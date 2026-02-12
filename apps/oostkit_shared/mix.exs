defmodule OostkitShared.MixProject do
  use Mix.Project

  def project do
    [
      app: :oostkit_shared,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17 or ~> 1.18 or ~> 1.19",
      deps: deps()
    ]
  end

  defp deps do
    [{:phoenix_live_view, "~> 1.0"}]
  end
end
