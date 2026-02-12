import Config

# Configure your database
config :workgroup_pulse, WorkgroupPulse.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "workgroup_pulse_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable debugging
config :workgroup_pulse, WorkgroupPulseWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_that_is_at_least_64_characters_long_for_development_only",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:workgroup_pulse, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:workgroup_pulse, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading
config :workgroup_pulse, WorkgroupPulseWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/workgroup_pulse_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :workgroup_pulse, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Note: enable_expensive_runtime_checks causes high CPU in Docker.
# Set PHOENIX_EXPENSIVE_CHECKS=true to enable when debugging LiveView issues.
config :phoenix_live_view,
  debug_heex_annotations: true,
  enable_expensive_runtime_checks: System.get_env("PHOENIX_EXPENSIVE_CHECKS") == "true"

# Portal URL for OOSTKit header link
config :workgroup_pulse, :portal_url, "http://localhost:4002"

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
