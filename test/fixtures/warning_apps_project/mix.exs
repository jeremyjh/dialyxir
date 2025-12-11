defmodule WarningAppsProject.Mixfile do
  use Mix.Project

  def project do
    [
      app: :warning_apps_project,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: [
          enabled: true,
          warning_apps: :apps_direct
        ]
      ]
    ]
  end
end
