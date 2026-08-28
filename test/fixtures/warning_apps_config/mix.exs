defmodule WarningAppsConfig.Mixfile do
  use Mix.Project

  def project do
    [
      app: :warning_apps_config,
      prune_code_paths: false,
      version: "0.1.0",
      deps: deps(),
      dialyzer: [incremental: true, warning_apps: [:elixir]]
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
