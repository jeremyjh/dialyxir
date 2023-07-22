defmodule PltAddDepsDeprecations.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plt_add_deps_deprecations,
      prune_code_paths: false,
      version: "0.1.0",
      dialyzer: [
        plt_add_deps: true
      ]
    ]
  end
end
