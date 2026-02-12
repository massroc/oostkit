import Config

# =============================================================================
# Portal (test)
# =============================================================================

config :bcrypt_elixir, :log_rounds, 1

config :portal, Portal.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "portal_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :portal, PortalWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4004],
  secret_key_base: "portal_test_secret_key_base_that_is_at_least_64_characters_long_for_test",
  server: false

config :portal, Portal.Mailer, adapter: Swoosh.Adapters.Test

config :portal, :internal_api_key, "test_internal_api_key"

config :portal, :tool_urls, %{
  "workgroup_pulse" => "http://localhost:4000",
  "wrt" => "http://localhost:4001"
}

config :portal, :start_status_poller, false

config :portal, :github_repo, "rossm/oostkit"

# =============================================================================
# Workgroup Pulse (test)
# =============================================================================

config :workgroup_pulse, WorkgroupPulse.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "workgroup_pulse_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# server: true needed for Wallaby E2E tests
config :workgroup_pulse, WorkgroupPulseWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_that_is_at_least_64_characters_long_for_testing_only",
  server: true

config :workgroup_pulse, WorkgroupPulse.Mailer, adapter: Swoosh.Adapters.Test

config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :wallaby,
  driver: Wallaby.Chrome,
  screenshot_on_failure: true,
  js_errors: true,
  chromedriver: [
    path: System.get_env("CHROMEDRIVER_PATH", "/usr/bin/chromedriver"),
    headless: true
  ],
  chrome: [
    headless: true
  ]

# =============================================================================
# WRT (test)
# =============================================================================

config :wrt, Wrt.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "wrt_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :wrt, WrtWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4003],
  secret_key_base: "wrt_test_secret_key_base_that_is_at_least_64_characters_long_for_testing",
  server: false

config :wrt, Wrt.Mailer, adapter: Swoosh.Adapters.Test

config :wrt, Oban, testing: :inline

config :wrt, WrtWeb.Plugs.RateLimiter, enabled: false

config :wrt, :portal_api_url, "http://localhost:4002"
config :wrt, :portal_api_key, "test_internal_api_key"
config :wrt, :portal_login_url, "http://localhost:4002/users/log-in"

# =============================================================================
# Shared test settings
# =============================================================================

config :swoosh, :api_client, false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
