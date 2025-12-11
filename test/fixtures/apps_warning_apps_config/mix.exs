defmodule AppsWarningAppsConfig.Mixfile do
  use Mix.Project

  def project do
    [
      app: :apps_warning_apps_config,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: [
          enabled: true,
          apps: [:kernel, :stdlib, :apps_warning_apps_config],
          warning_apps: [:apps_warning_apps_config]
        ]
      ]
    ]
  end
end
