# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

config :workgroup_pulse,
  ecto_repos: [WorkgroupPulse.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :workgroup_pulse, WorkgroupPulseWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: WorkgroupPulseWeb.ErrorHTML, json: WorkgroupPulseWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: WorkgroupPulse.PubSub,
  live_view: [signing_salt: "workgroup_pulse_salt"]

# Configures the mailer (using Swoosh)
config :workgroup_pulse, WorkgroupPulse.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.24.2",
  workgroup_pulse: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.17",
  workgroup_pulse: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configure Petal Components error translator
config :petal_components, :error_translator_function, {WorkgroupPulseWeb.CoreComponents, :translate_error}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config
import_config "#{config_env()}.exs"
