defmodule PortalWeb.Plugs.RateLimiterTest do
  use PortalWeb.ConnCase, async: false

  alias PortalWeb.Plugs.RateLimiter

  # Start ETS storage for tests
  setup do
    # Ensure ETS table exists for rate limiter storage
    case :ets.info(PortalWeb.Plugs.RateLimiter.Storage) do
      :undefined ->
        PlugAttack.Storage.Ets.start_link(
          name: PortalWeb.Plugs.RateLimiter.Storage,
          clean_period: 60_000
        )

      _ ->
        :ets.delete_all_objects(PortalWeb.Plugs.RateLimiter.Storage)
    end

    # Enable rate limiter for these tests
    original = Application.get_env(:portal, PortalWeb.Plugs.RateLimiter)
    Application.put_env(:portal, PortalWeb.Plugs.RateLimiter, enabled: true)

    on_exit(fn ->
      if original do
        Application.put_env(:portal, PortalWeb.Plugs.RateLimiter, original)
      else
        Application.delete_env(:portal, PortalWeb.Plugs.RateLimiter)
      end
    end)

    :ok
  end

  # Helper to call the rate limiter plug directly on a synthetic conn
  defp rate_limit(method, path) do
    Plug.Test.conn(method, path)
    |> Map.put(:remote_ip, {127, 0, 0, 1})
    |> RateLimiter.call(RateLimiter.init([]))
  end

  describe "disabled rate limiter" do
    test "passes through when disabled" do
      Application.put_env(:portal, PortalWeb.Plugs.RateLimiter, enabled: false)

      conn = rate_limit(:post, "/users/log-in")
      refute conn.status == 429
      refute conn.halted
    end
  end

  describe "login rate limiting" do
    test "allows requests within limit" do
      for _ <- 1..5 do
        conn = rate_limit(:post, "/users/log-in")
        refute conn.status == 429
      end
    end

    test "blocks requests exceeding limit" do
      for _ <- 1..5 do
        rate_limit(:post, "/users/log-in")
      end

      conn = rate_limit(:post, "/users/log-in")
      assert conn.status == 429
      assert Jason.decode!(conn.resp_body)["error"] =~ "Too many requests"
    end
  end

  describe "magic link rate limiting" do
    test "blocks after 3 requests" do
      for _ <- 1..3 do
        rate_limit(:post, "/users/log-in/magic-link")
      end

      conn = rate_limit(:post, "/users/log-in/magic-link")
      assert conn.status == 429
    end
  end

  describe "password reset rate limiting" do
    test "blocks after 3 requests" do
      for _ <- 1..3 do
        rate_limit(:post, "/users/reset-password")
      end

      conn = rate_limit(:post, "/users/reset-password")
      assert conn.status == 429
    end
  end

  describe "registration rate limiting" do
    test "blocks after 5 requests" do
      for _ <- 1..5 do
        rate_limit(:post, "/users/register")
      end

      conn = rate_limit(:post, "/users/register")
      assert conn.status == 429
    end
  end

  describe "internal API rate limiting" do
    test "blocks after 60 requests" do
      for _ <- 1..60 do
        rate_limit(:post, "/api/internal/auth/validate")
      end

      conn = rate_limit(:post, "/api/internal/auth/validate")
      assert conn.status == 429
    end
  end

  describe "general rate limiting" do
    test "allows normal browsing within limit" do
      conn = rate_limit(:get, "/")
      refute conn.status == 429
      refute conn.halted
    end
  end

  describe "rate limit headers" do
    test "includes rate limit headers in response" do
      conn = get(build_conn(), ~p"/health")
      assert get_resp_header(conn, "x-ratelimit-limit") != []
      assert get_resp_header(conn, "x-ratelimit-remaining") != []
      assert get_resp_header(conn, "x-ratelimit-reset") != []
    end
  end

  describe "path matchers" do
    test "login_path? matches POST /users/log-in" do
      conn = %Plug.Conn{method: "POST", request_path: "/users/log-in"}
      assert RateLimiter.login_path?(conn)
    end

    test "login_path? does not match GET /users/log-in" do
      conn = %Plug.Conn{method: "GET", request_path: "/users/log-in"}
      refute RateLimiter.login_path?(conn)
    end

    test "magic_link_path? matches POST /users/log-in/magic-link" do
      conn = %Plug.Conn{method: "POST", request_path: "/users/log-in/magic-link"}
      assert RateLimiter.magic_link_path?(conn)
    end

    test "reset_password_path? matches POST /users/reset-password" do
      conn = %Plug.Conn{method: "POST", request_path: "/users/reset-password"}
      assert RateLimiter.reset_password_path?(conn)
    end

    test "registration_path? matches POST /users/register" do
      conn = %Plug.Conn{method: "POST", request_path: "/users/register"}
      assert RateLimiter.registration_path?(conn)
    end

    test "internal_api_path? matches POST /api/internal/auth/validate" do
      conn = %Plug.Conn{method: "POST", request_path: "/api/internal/auth/validate"}
      assert RateLimiter.internal_api_path?(conn)
    end

    test "internal_api_path? does not match GET" do
      conn = %Plug.Conn{method: "GET", request_path: "/api/internal/auth/validate"}
      refute RateLimiter.internal_api_path?(conn)
    end
  end
end
