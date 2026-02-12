defmodule Wrt.MixProject do
  use Mix.Project

  def project do
    [
      app: :wrt,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17 or ~> 1.18 or ~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      listeners: [Phoenix.CodeReloader],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix, :ex_unit]
      ]
    ]
  end

  def application do
    [
      mod: {Wrt.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix core
      {:phoenix, "~> 1.7.18 or ~> 1.8.0"},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.17"},
      {:finch, "~> 0.19"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},
      {:gettext, "~> 0.26.0"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.1.3 or ~> 0.2.0"},
      {:bandit, "~> 1.6"},

      # UI Components
      {:petal_components, "~> 2.0"},
      {:phoenix_html_helpers, "~> 1.0"},

      # Multi-tenancy (using fork with deprecation fix until PR #95 is merged)
      {:triplex, github: "PaulOstazeski/triplex", branch: "master"},

      # Background jobs
      {:oban, "~> 2.17"},

      # Authentication
      {:bcrypt_elixir, "~> 3.1"},

      # CSV export
      {:nimble_csv, "~> 1.2"},

      # PDF generation
      {:chromic_pdf, "~> 1.14"},

      # Rate limiting
      {:plug_attack, "~> 0.4"},

      # Testing
      {:floki, "~> 0.38", only: :test},
      {:ex_machina, "~> 2.8", only: :test},
      {:faker, "~> 0.18", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:mox, "~> 1.2", only: :test},

      # Shared components
      {:oostkit_shared, in_umbrella: true},

      # Development
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind wrt", "esbuild wrt"],
      "assets.deploy": [
        "tailwind wrt --minify",
        "esbuild wrt --minify",
        "phx.digest"
      ],
      quality: ["format --check-formatted", "credo --strict", "sobelow --config"]
    ]
  end
end
