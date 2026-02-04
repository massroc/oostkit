import Config

# Configure your database for testing
config :wrt, Wrt.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "wrt_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Configure endpoint for testing
config :wrt, WrtWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4003],
  secret_key_base: "wrt_test_secret_key_base_that_is_at_least_64_characters_long_for_testing",
  server: false

# In test we don't send emails
config :wrt, Wrt.Mailer, adapter: Swoosh.Adapters.Test

# Disable Oban in tests (use manual mode)
config :wrt, Oban, testing: :inline

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Disable rate limiting in tests
config :wrt, WrtWeb.Plugs.RateLimiter, enabled: false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
