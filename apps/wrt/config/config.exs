# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

config :wrt,
  ecto_repos: [Wrt.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :wrt, WrtWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: WrtWeb.ErrorHTML, json: WrtWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Wrt.PubSub

# Configures the mailer (using Swoosh)
config :wrt, Wrt.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.24.2",
  wrt: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.17",
  wrt: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Oban for background jobs
config :wrt, Oban,
  repo: Wrt.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10, emails: 20, rounds: 5, maintenance: 2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config
import_config "#{config_env()}.exs"
