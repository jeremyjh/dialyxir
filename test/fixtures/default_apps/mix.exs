defmodule DefaultApps.Mixfile do
  use Mix.Project

  def project do
    [app: :default_apps, prune_code_paths: false, version: "0.1.0", deps: deps()]
  end

  def application do
    [applications: [:logger, :public_key]]
  end

  defp deps do
    []
  end
end
