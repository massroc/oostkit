defmodule Portal.MixProject do
  use Mix.Project

  def project do
    [
      app: :portal,
      version: "0.1.0",
      elixir: "~> 1.17 or ~> 1.18 or ~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases(),
      test_coverage: [tool: ExCoveralls],
      listeners: [Phoenix.CodeReloader],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.json": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix, :ex_unit]
      ]
    ]
  end

  def application do
    [
      mod: {Portal.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp releases do
    [
      portal: [
        include_executables_for: [:unix],
        overlays: ["rel/overlays"]
      ]
    ]
  end

  defp deps do
    [
      # Phoenix core
      {:phoenix, "~> 1.7.18 or ~> 1.8.0"},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
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

      # HTTP client
      {:req, "~> 0.5"},

      # UI Components
      {:petal_components, "~> 2.0"},
      {:phoenix_html_helpers, "~> 1.0"},

      # Authentication
      {:bcrypt_elixir, "~> 3.1"},

      # Testing
      {:excoveralls, "~> 0.18", only: :test},
      {:floki, "~> 0.38", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},

      # Shared components
      {:oostkit_shared, path: "../oostkit_shared"},

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
      "assets.build": ["tailwind portal", "esbuild portal"],
      "assets.deploy": [
        "tailwind portal --minify",
        "esbuild portal --minify",
        "phx.digest"
      ],
      quality: ["format --check-formatted", "credo --strict", "sobelow --config"]
    ]
  end
end
