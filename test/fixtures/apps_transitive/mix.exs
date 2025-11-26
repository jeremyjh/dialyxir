defmodule AppsTransitive.Mixfile do
  use Mix.Project

  def project do
    [
      app: :apps_transitive,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: true,
        core_apps: [:erts, :kernel, :stdlib, :elixir],
        apps: :transitive
      ]
    ]
  end
end
