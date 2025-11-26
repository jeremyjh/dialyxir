defmodule CoreAppsConfig.Mixfile do
  use Mix.Project

  def project do
    [
      app: :core_apps_config,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: true,
        core_apps: [:erts, :kernel, :stdlib, :crypto, :public_key, :ssl, :elixir, :logger]
      ]
    ]
  end
end
