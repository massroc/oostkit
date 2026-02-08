# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

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

# Configures the endpoint
config :portal, PortalWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PortalWeb.ErrorHTML, json: PortalWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Portal.PubSub,
  live_view: [signing_salt: "portal_lv_salt"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.24.2",
  portal: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.17",
  portal: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures the mailer (using Swoosh)
config :portal, Portal.Mailer, adapter: Swoosh.Adapters.Local

# Configure Petal Components error translator
config :petal_components,
       :error_translator_function,
       {PortalWeb.CoreComponents, :translate_error}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config
import_config "#{config_env()}.exs"
