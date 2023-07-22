defmodule NonexistentDeps.Mixfile do
  use Mix.Project

  def project do
    [
      app: :nonexistent_deps,
      prune_code_paths: false,
      version: "0.1.0",
      deps: deps()
    ]
  end

  def application do
    # This application has a run-time dependency on a non-existent
    # application.
    [applications: [:logger, :public_key, :nonexistent]]
  end

  defp deps do
    []
  end
end
