import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database for testing
config :portal, Portal.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "portal_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Configure endpoint for testing
config :portal, PortalWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4004],
  secret_key_base: "portal_test_secret_key_base_that_is_at_least_64_characters_long_for_test",
  server: false

# In test we don't send emails
config :portal, Portal.Mailer, adapter: Swoosh.Adapters.Test

# Internal API key for cross-app auth
config :portal, :internal_api_key, "test_internal_api_key"

# Tool URLs for test environment
config :portal, :tool_urls, %{
  "workgroup_pulse" => "http://localhost:4000",
  "wrt" => "http://localhost:4001"
}

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
