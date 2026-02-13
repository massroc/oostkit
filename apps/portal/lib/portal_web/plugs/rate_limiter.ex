defmodule PortalWeb.Plugs.RateLimiter do
  @moduledoc """
  Rate limiting plug using PlugAttack.

  Applies different rate limits based on the type of request:
  - Login attempts: 5 per minute per IP
  - Magic link requests: 3 per minute per IP
  - Password reset requests: 3 per minute per IP
  - Registration: 5 per minute per IP
  - Internal API validation: 60 per minute per IP
  - General: 120 per minute per IP

  Can be disabled via config:
    config :portal, PortalWeb.Plugs.RateLimiter, enabled: false
  """

  @behaviour Plug

  alias PortalWeb.Plugs.RateLimiter.Rules

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    if enabled?() do
      Rules.call(conn, opts)
    else
      conn
    end
  end

  defp enabled? do
    Application.get_env(:portal, __MODULE__, [])
    |> Keyword.get(:enabled, true)
  end

  # Path matchers used by Rules

  def login_path?(conn) do
    conn.method == "POST" and conn.request_path == "/users/log-in"
  end

  def magic_link_path?(conn) do
    conn.method == "POST" and
      String.starts_with?(conn.request_path, "/users/log-in/magic-link")
  end

  def reset_password_path?(conn) do
    conn.method == "POST" and conn.request_path == "/users/reset-password"
  end

  def registration_path?(conn) do
    conn.method == "POST" and conn.request_path == "/users/register"
  end

  def internal_api_path?(conn) do
    conn.method == "POST" and
      String.starts_with?(conn.request_path, "/api/internal/")
  end
end

defmodule PortalWeb.Plugs.RateLimiter.Rules do
  @moduledoc false
  use PlugAttack
  import Plug.Conn
  alias PortalWeb.Plugs.RateLimiter

  @storage {PlugAttack.Storage.Ets, PortalWeb.Plugs.RateLimiter.Storage}

  rule "throttle login attempts", conn do
    if RateLimiter.login_path?(conn) do
      throttle(
        ip_to_string(conn.remote_ip),
        period: 60_000,
        limit: 5,
        storage: @storage
      )
    end
  end

  rule "throttle magic link requests", conn do
    if RateLimiter.magic_link_path?(conn) do
      throttle(
        ip_to_string(conn.remote_ip),
        period: 60_000,
        limit: 3,
        storage: @storage
      )
    end
  end

  rule "throttle password reset requests", conn do
    if RateLimiter.reset_password_path?(conn) do
      throttle(
        ip_to_string(conn.remote_ip),
        period: 60_000,
        limit: 3,
        storage: @storage
      )
    end
  end

  rule "throttle registration", conn do
    if RateLimiter.registration_path?(conn) do
      throttle(
        ip_to_string(conn.remote_ip),
        period: 60_000,
        limit: 5,
        storage: @storage
      )
    end
  end

  rule "throttle internal API", conn do
    if RateLimiter.internal_api_path?(conn) do
      throttle(
        ip_to_string(conn.remote_ip),
        period: 60_000,
        limit: 60,
        storage: @storage
      )
    end
  end

  rule "general rate limit", conn do
    throttle(
      ip_to_string(conn.remote_ip),
      period: 60_000,
      limit: 120,
      storage: @storage
    )
  end

  defp ip_to_string(ip) when is_tuple(ip), do: :inet.ntoa(ip) |> to_string()
  defp ip_to_string(ip), do: to_string(ip)

  def block_action(conn, _data, _opts) do
    require Logger

    Logger.warning("Rate limit exceeded",
      category: :security,
      event: :rate_limited,
      ip: ip_to_string(conn.remote_ip),
      path: conn.request_path
    )

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(429, Jason.encode!(%{error: "Too many requests. Please try again later."}))
    |> halt()
  end

  def allow_action(conn, {:throttle, data}, _opts) do
    conn
    |> put_resp_header("x-ratelimit-limit", to_string(data[:limit]))
    |> put_resp_header("x-ratelimit-remaining", to_string(data[:remaining]))
    |> put_resp_header("x-ratelimit-reset", to_string(data[:expires_at]))
  end

  def allow_action(conn, _data, _opts), do: conn
end
