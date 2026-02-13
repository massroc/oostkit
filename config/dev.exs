import Config

# =============================================================================
# Portal (dev)
# =============================================================================

config :portal, Portal.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "portal_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

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

config :portal, PortalWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/portal_web/(controllers|components|live)/.*(ex|heex)$"
    ]
  ]

config :portal, dev_routes: true

config :portal, :internal_api_key, "dev_internal_api_key"

config :portal, :tool_urls, %{
  "workgroup_pulse" => "http://localhost:4000",
  "wrt" => "http://localhost:4001"
}

config :portal, :tool_status_overrides, %{
  "wrt" => "live"
}

# =============================================================================
# Workgroup Pulse (dev)
# =============================================================================

config :workgroup_pulse, WorkgroupPulse.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "workgroup_pulse_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

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

config :workgroup_pulse, WorkgroupPulseWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/workgroup_pulse_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :workgroup_pulse, dev_routes: true

config :workgroup_pulse, :portal_url, "http://localhost:4002"

config :phoenix_live_view,
  debug_heex_annotations: true,
  enable_expensive_runtime_checks: System.get_env("PHOENIX_EXPENSIVE_CHECKS") == "true"

# =============================================================================
# WRT (dev)
# =============================================================================

config :wrt, Wrt.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  database: "wrt_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

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

config :wrt, WrtWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/wrt_web/(controllers|components)/.*(ex|heex)$"
    ]
  ]

config :wrt, dev_routes: true

config :wrt, :portal_url, "http://localhost:4002"

config :oostkit_shared, :portal_auth,
  api_url: "http://localhost:4002",
  api_key: "dev_internal_api_key",
  login_url: "http://localhost:4002/users/log-in",
  finch: Wrt.Finch

# =============================================================================
# Shared dev settings
# =============================================================================

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
