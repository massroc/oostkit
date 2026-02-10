import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# temporary configuration is applied in migration scripts.

if System.get_env("PHX_SERVER") do
  config :portal, PortalWeb.Endpoint, server: true
end

if config_env() == :prod do
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

  # The secret key base is used to sign/encrypt cookies and other secrets.
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
  # MAIL_ADAPTER options:
  #   - "postmark" (default if POSTMARK_API_KEY set) - sends real emails
  #   - "logger" - logs emails to stdout (useful for staging)
  #   - unset without POSTMARK_API_KEY - emails silently dropped
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

  # Internal API key for cross-app auth
  config :portal,
    :internal_api_key,
    System.get_env("INTERNAL_API_KEY") ||
      raise("environment variable INTERNAL_API_KEY is missing")

  # Cross-app cookie domain (e.g., ".oostkit.com")
  cookie_domain = System.get_env("COOKIE_DOMAIN")
  if cookie_domain, do: config(:portal, :cookie_domain, cookie_domain)

  # Configurable from-address
  config :portal, :mail_from,
    name: System.get_env("MAIL_FROM_NAME", "OOSTKit"),
    address: System.get_env("MAIL_FROM_ADDRESS", "noreply@oostkit.com")
end
