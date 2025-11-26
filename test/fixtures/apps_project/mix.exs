defmodule AppsProject.Mixfile do
  use Mix.Project

  def project do
    [
      app: :apps_project,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: true,
        apps: :project
      ]
    ]
  end
end
