import Config

# Configure your database
config :portal, Portal.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "portal_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable debugging
config :portal, PortalWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4002],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "portal_dev_secret_key_base_that_is_at_least_64_characters_long_for_dev",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:portal, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:portal, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading
config :portal, PortalWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/portal_web/(controllers|components|live)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :portal, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
