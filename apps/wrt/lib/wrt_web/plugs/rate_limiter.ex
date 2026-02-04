defmodule WrtWeb.Plugs.RateLimiter do
  @moduledoc """
  Rate limiting plug using PlugAttack.

  Applies different rate limits based on the type of request:
  - Login attempts: 5 per minute per IP
  - Magic link requests: 3 per minute per IP
  - Nomination submissions: 10 per minute per session
  - Webhook endpoints: 100 per minute per IP
  - General API: 60 per minute per IP

  Can be disabled via config:
    config :wrt, WrtWeb.Plugs.RateLimiter, enabled: false
  """

  @behaviour Plug

  import Plug.Conn

  alias WrtWeb.Plugs.RateLimiter.Rules

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
    Application.get_env(:wrt, __MODULE__, [])
    |> Keyword.get(:enabled, true)
  end

  # Path matchers used by both this module and Rules

  def login_path?(conn) do
    conn.method == "POST" and
      (String.ends_with?(conn.request_path, "/login") or
         String.contains?(conn.request_path, "/session"))
  end

  def magic_link_path?(conn) do
    conn.method == "POST" and String.contains?(conn.request_path, "/request-link")
  end

  def nomination_path?(conn) do
    conn.method == "POST" and String.contains?(conn.request_path, "/nominate/submit")
  end

  def webhook_path?(conn) do
    String.starts_with?(conn.request_path, "/webhooks")
  end
end

defmodule WrtWeb.Plugs.RateLimiter.Rules do
  @moduledoc false
  use PlugAttack
  import Plug.Conn
  alias WrtWeb.Plugs.RateLimiter

  # Storage for rate limit counters (uses ETS)
  @storage {PlugAttack.Storage.Ets, WrtWeb.Plugs.RateLimiter.Storage, [clean_period: 60_000]}

  # Rate limit rules

  rule "throttle login attempts", conn do
    if RateLimiter.login_path?(conn) do
      throttle(
        conn.remote_ip,
        period: 60_000,
        limit: 5,
        storage: @storage
      )
    end
  end

  rule "throttle magic link requests", conn do
    if RateLimiter.magic_link_path?(conn) do
      throttle(
        conn.remote_ip,
        period: 60_000,
        limit: 3,
        storage: @storage
      )
    end
  end

  rule "throttle nomination submissions", conn do
    if RateLimiter.nomination_path?(conn) do
      # Use session ID if available, otherwise IP
      key = get_session(conn, :nominator_person_id) || conn.remote_ip

      throttle(
        key,
        period: 60_000,
        limit: 10,
        storage: @storage
      )
    end
  end

  rule "throttle webhooks", conn do
    if RateLimiter.webhook_path?(conn) do
      throttle(
        conn.remote_ip,
        period: 60_000,
        limit: 100,
        storage: @storage
      )
    end
  end

  rule "general rate limit", conn do
    # General rate limit for all other requests
    throttle(
      conn.remote_ip,
      period: 60_000,
      limit: 120,
      storage: @storage
    )
  end

  # Handle blocked requests

  def block_action(conn, _data, _opts) do
    # Log the rate limit event
    Wrt.Logger.log_rate_limit(conn.remote_ip, conn.request_path)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(429, Jason.encode!(%{error: "Too many requests. Please try again later."}))
    |> halt()
  end

  # Handle allowed requests (add rate limit headers)

  def allow_action(conn, {:throttle, data}, _opts) do
    conn
    |> put_resp_header("x-ratelimit-limit", to_string(data[:limit]))
    |> put_resp_header("x-ratelimit-remaining", to_string(data[:remaining]))
    |> put_resp_header("x-ratelimit-reset", to_string(data[:expires_at]))
  end

  def allow_action(conn, _data, _opts), do: conn
end
