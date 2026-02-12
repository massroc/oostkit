defmodule Oostkit.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: releases()
    ]
  end

  defp deps do
    []
  end

  defp releases do
    [
      portal: [
        applications: [portal: :permanent],
        include_executables_for: [:unix],
        overlays: ["apps/portal/rel/overlays"]
      ],
      workgroup_pulse: [
        applications: [workgroup_pulse: :permanent],
        include_executables_for: [:unix],
        overlays: ["apps/workgroup_pulse/rel/overlays"]
      ],
      wrt: [
        applications: [wrt: :permanent],
        include_executables_for: [:unix],
        overlays: ["apps/wrt/rel/overlays"]
      ]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
