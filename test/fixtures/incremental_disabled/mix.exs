defmodule IncrementalDisabled.Mixfile do
  use Mix.Project

  def project do
    [
      app: :incremental_disabled,
      prune_code_paths: false,
      version: "0.1.0",
      deps: deps(),
      dialyzer: [incremental: false]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
