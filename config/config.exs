# Root umbrella configuration
# Each app's config is scoped by its OTP name (:portal, :workgroup_pulse, :wrt)
import Config

# =============================================================================
# Shared library/framework config
# =============================================================================

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# =============================================================================
# Portal
# =============================================================================

config :portal, :scopes,
  user: [
    default: true,
    module: Portal.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: Portal.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :portal,
  ecto_repos: [Portal.Repo],
  generators: [timestamp_type: :utc_datetime]

config :portal, PortalWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PortalWeb.ErrorHTML, json: PortalWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Portal.PubSub,
  live_view: [signing_salt: "portal_lv_salt"]

config :portal, Portal.Mailer, adapter: Swoosh.Adapters.Local

config :portal, :mail_from,
  name: "OOSTKit",
  address: "noreply@oostkit.com"

# =============================================================================
# Workgroup Pulse
# =============================================================================

config :workgroup_pulse,
  ecto_repos: [WorkgroupPulse.Repo],
  generators: [timestamp_type: :utc_datetime]

config :workgroup_pulse, WorkgroupPulseWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: WorkgroupPulseWeb.ErrorHTML, json: WorkgroupPulseWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: WorkgroupPulse.PubSub,
  live_view: [signing_salt: "workgroup_pulse_salt"]

config :workgroup_pulse, WorkgroupPulse.Mailer, adapter: Swoosh.Adapters.Local

# =============================================================================
# WRT
# =============================================================================

config :wrt,
  ecto_repos: [Wrt.Repo],
  generators: [timestamp_type: :utc_datetime]

config :wrt, WrtWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: WrtWeb.ErrorHTML, json: WrtWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Wrt.PubSub

config :wrt, Wrt.Mailer, adapter: Swoosh.Adapters.Local

config :wrt, Oban,
  repo: Wrt.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       {"0 3 * * *", Wrt.Workers.CleanupExpiredMagicLinks},
       {"0 4 * * 0", Wrt.Workers.DataRetentionCheck, args: %{action: "check"}}
     ]}
  ],
  queues: [default: 10, emails: 20, rounds: 5, maintenance: 2]

# =============================================================================
# Esbuild (asset bundler)
# =============================================================================

config :esbuild,
  version: "0.24.2",
  portal: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/portal/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  workgroup_pulse: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/workgroup_pulse/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ],
  wrt: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/wrt/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# =============================================================================
# Tailwind CSS
# =============================================================================

config :tailwind,
  version: "3.4.17",
  portal: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/portal/assets", __DIR__)
  ],
  workgroup_pulse: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/workgroup_pulse/assets", __DIR__)
  ],
  wrt: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/wrt/assets", __DIR__)
  ]

# =============================================================================
# Petal Components — last app's translator wins at compile time, but each app
# overrides this in its own CoreComponents module at runtime via use/import.
# Set a default here; apps override via their own config if needed.
# =============================================================================

config :petal_components,
       :error_translator_function,
       {PortalWeb.CoreComponents, :translate_error}

# Import environment specific config
import_config "#{config_env()}.exs"
