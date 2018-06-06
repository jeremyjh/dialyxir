defmodule DirectApps.Mixfile do
  use Mix.Project

  def project do
    [app: :direct_apps, version: "0.1.0", deps: deps(), dialyzer: [plt_add_deps: :apps_direct]]
  end

  def application do
    [applications: [:logger, :public_key]]
  end

  defp deps do
    []
  end
end
