defmodule IncrementalEnabled.Mixfile do
  use Mix.Project

  def project do
    [
      app: :incremental_enabled,
      prune_code_paths: false,
      version: "0.1.0",
      deps: deps(),
      dialyzer: [incremental: true]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
