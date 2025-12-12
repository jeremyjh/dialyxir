defmodule AppsConfig.Mixfile do
  use Mix.Project

  def project do
    [
      app: :apps_config,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: [
          enabled: true,
          apps: [:apps_config, :kernel]
        ]
      ]
    ]
  end
end
