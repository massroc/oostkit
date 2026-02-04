import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# temporary configuration is applied in migration scripts.

if System.get_env("PHX_SERVER") do
  config :wrt, WrtWeb.Endpoint, server: true
end

if config_env() == :prod do
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

  # The secret key base is used to sign/encrypt cookies and other secrets.
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
  # MAIL_ADAPTER options:
  #   - "postmark" (default if POSTMARK_API_KEY set) - sends real emails
  #   - "logger" - logs emails to stdout (useful for staging)
  #   - unset without POSTMARK_API_KEY - emails silently dropped
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
      # No adapter configured - emails will fail
      # This is intentional to catch missing config in staging/prod
      :ok
  end

  # Data retention configuration
  config :wrt, :data_retention,
    campaign_retention_months: 24,
    warning_days_before_deletion: 30
end
