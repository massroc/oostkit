import Config

# Configure your database
config :wrt, Wrt.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "wrt_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable debugging
config :wrt, WrtWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "wrt_dev_secret_key_base_that_is_at_least_64_characters_long_for_development",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:wrt, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:wrt, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading
config :wrt, WrtWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/wrt_web/(controllers|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :wrt, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Portal cross-app auth
config :wrt, :portal_api_url, "http://localhost:4002"
config :wrt, :portal_api_key, "dev_internal_api_key"
config :wrt, :portal_login_url, "http://localhost:4002/users/log-in"

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
