import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# temporary configuration is applied in migration scripts.
#
# In the umbrella, each release only contains one app. We use
# Code.ensure_loaded?/1 to guard app-specific config so it only
# activates in the correct release.

# =============================================================================
# Portal runtime
# =============================================================================

if System.get_env("PHX_SERVER") do
  if Code.ensure_loaded?(PortalWeb.Endpoint) do
    config :portal, PortalWeb.Endpoint, server: true
  end

  if Code.ensure_loaded?(WorkgroupPulseWeb.Endpoint) do
    config :workgroup_pulse, WorkgroupPulseWeb.Endpoint, server: true
  end

  if Code.ensure_loaded?(WrtWeb.Endpoint) do
    config :wrt, WrtWeb.Endpoint, server: true
  end
end

# Workgroup Pulse: Portal URL (all envs — dev.exs sets localhost default)
if portal_url = System.get_env("PORTAL_URL") do
  config :workgroup_pulse, :portal_url, portal_url
end

# Workgroup Pulse: PostHog analytics (optional — set POSTHOG_API_KEY to enable)
posthog_key = System.get_env("POSTHOG_API_KEY")
posthog_host = System.get_env("POSTHOG_HOST") || "https://us.i.posthog.com"

config :workgroup_pulse, :posthog,
  api_key: posthog_key,
  host: posthog_host,
  enabled: posthog_key != nil

# =============================================================================
# Production-only runtime config
# =============================================================================

if config_env() == :prod do
  # ---------------------------------------------------------------------------
  # Portal
  # ---------------------------------------------------------------------------

  if Code.ensure_loaded?(Portal.Repo) do
    database_url =
      System.get_env("DATABASE_URL") ||
        raise """
        environment variable DATABASE_URL is missing.
        For example: ecto://USER:PASS@HOST/DATABASE
        """

    maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

    config :portal, Portal.Repo,
      url: database_url,
      pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
      socket_options: maybe_ipv6

    secret_key_base =
      System.get_env("SECRET_KEY_BASE") ||
        raise """
        environment variable SECRET_KEY_BASE is missing.
        You can generate one by calling: mix phx.gen.secret
        """

    host = System.get_env("PHX_HOST") || "oostkit.com"
    port = String.to_integer(System.get_env("PORT") || "4002")

    config :portal, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

    config :portal, PortalWeb.Endpoint,
      url: [host: host, port: 443, scheme: "https"],
      http: [
        ip: {0, 0, 0, 0, 0, 0, 0, 0},
        port: port
      ],
      secret_key_base: secret_key_base

    # Email configuration
    mail_adapter = System.get_env("MAIL_ADAPTER")
    postmark_api_key = System.get_env("POSTMARK_API_KEY")

    cond do
      mail_adapter == "logger" ->
        config :portal, Portal.Mailer, adapter: Swoosh.Adapters.Logger

      postmark_api_key != nil ->
        config :portal, Portal.Mailer,
          adapter: Swoosh.Adapters.Postmark,
          api_key: postmark_api_key

      true ->
        :ok
    end

    # Swoosh Finch instance for Portal release
    config :swoosh, finch_name: Portal.Finch

    config :portal,
           :internal_api_key,
           System.get_env("INTERNAL_API_KEY") ||
             raise("environment variable INTERNAL_API_KEY is missing")

    cookie_domain = System.get_env("COOKIE_DOMAIN")
    if cookie_domain, do: config(:portal, :cookie_domain, cookie_domain)

    config :portal, :tool_urls, %{
      "workgroup_pulse" => System.get_env("PULSE_URL", "https://pulse.oostkit.com"),
      "wrt" => System.get_env("WRT_URL", "https://wrt.oostkit.com")
    }

    config :portal, :mail_from,
      name: System.get_env("MAIL_FROM_NAME", "OOSTKit"),
      address: System.get_env("MAIL_FROM_ADDRESS", "noreply@oostkit.com")

    github_token = System.get_env("GITHUB_TOKEN")
    if github_token, do: config(:portal, :github_token, github_token)

    config :portal, :github_repo, System.get_env("GITHUB_REPO", "rossm/oostkit")
  end

  # ---------------------------------------------------------------------------
  # Workgroup Pulse
  # ---------------------------------------------------------------------------

  if Code.ensure_loaded?(WorkgroupPulse.Repo) do
    database_url =
      System.get_env("DATABASE_URL") ||
        raise """
        environment variable DATABASE_URL is missing.
        For example: ecto://USER:PASS@HOST/DATABASE
        """

    maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

    config :workgroup_pulse, WorkgroupPulse.Repo,
      url: database_url,
      pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
      socket_options: maybe_ipv6

    secret_key_base =
      System.get_env("SECRET_KEY_BASE") ||
        raise """
        environment variable SECRET_KEY_BASE is missing.
        You can generate one by calling: mix phx.gen.secret
        """

    host = System.get_env("PHX_HOST") || "example.com"
    port = String.to_integer(System.get_env("PORT") || "4000")

    config :workgroup_pulse, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

    config :workgroup_pulse, WorkgroupPulseWeb.Endpoint,
      url: [host: host, port: 443, scheme: "https"],
      http: [
        ip: {0, 0, 0, 0, 0, 0, 0, 0},
        port: port
      ],
      secret_key_base: secret_key_base

    # Session data cleanup
    config :workgroup_pulse, :session_cleanup,
      completed_retention_days: 90,
      incomplete_retention_days: 14
  end

  # ---------------------------------------------------------------------------
  # WRT
  # ---------------------------------------------------------------------------

  if Code.ensure_loaded?(Wrt.Repo) do
    database_url =
      System.get_env("DATABASE_URL") ||
        raise """
        environment variable DATABASE_URL is missing.
        For example: ecto://USER:PASS@HOST/DATABASE
        """

    maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

    config :wrt, Wrt.Repo,
      url: database_url,
      pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
      socket_options: maybe_ipv6

    secret_key_base =
      System.get_env("SECRET_KEY_BASE") ||
        raise """
        environment variable SECRET_KEY_BASE is missing.
        You can generate one by calling: mix phx.gen.secret
        """

    host = System.get_env("PHX_HOST") || "example.com"
    port = String.to_integer(System.get_env("PORT") || "4001")

    config :wrt, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

    config :wrt, WrtWeb.Endpoint,
      url: [host: host, port: 443, scheme: "https"],
      http: [
        ip: {0, 0, 0, 0, 0, 0, 0, 0},
        port: port
      ],
      secret_key_base: secret_key_base

    # Email configuration
    mail_adapter = System.get_env("MAIL_ADAPTER")
    postmark_api_key = System.get_env("POSTMARK_API_KEY")

    cond do
      mail_adapter == "logger" ->
        config :wrt, Wrt.Mailer, adapter: Swoosh.Adapters.Logger

      postmark_api_key != nil ->
        config :wrt, Wrt.Mailer,
          adapter: Swoosh.Adapters.Postmark,
          api_key: postmark_api_key

      true ->
        :ok
    end

    # Swoosh Finch instance for WRT release
    config :swoosh, finch_name: Wrt.Finch

    # Data retention configuration
    config :wrt, :data_retention,
      campaign_retention_months: 24,
      warning_days_before_deletion: 30

    # Portal cross-app auth
    config :wrt,
      portal_url: System.get_env("PORTAL_URL", "https://oostkit.com"),
      portal_api_url: System.get_env("PORTAL_API_URL", "http://oostkit-portal.flycast"),
      portal_api_key: System.get_env("PORTAL_API_KEY"),
      portal_login_url: System.get_env("PORTAL_LOGIN_URL", "https://oostkit.com/users/log-in")

    # Rate limiter configuration
    rate_limiter_enabled = System.get_env("RATE_LIMITER_ENABLED", "true") == "true"
    config :wrt, WrtWeb.Plugs.RateLimiter, enabled: rate_limiter_enabled
  end
end
