defmodule AppsTransitive.Mixfile do
  use Mix.Project

  def project do
    [
      app: :apps_transitive,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: [
          enabled: true,
          apps: :app_tree
        ]
      ]
    ]
  end
end
