defmodule IgnoreApps.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ignore_apps,
      version: "0.1.0",
      deps: deps(),
      dialyzer: [
        plt_ignore_apps: [:logger]
      ]
    ]
  end

  def application do
    [applications: [:logger, :public_key]]
  end

  defp deps do
    []
  end
end
