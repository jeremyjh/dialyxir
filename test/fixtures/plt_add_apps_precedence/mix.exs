defmodule PltAddAppsPrecedence.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plt_add_apps_precedence,
      prune_code_paths: false,
      version: "0.1.0",
      deps: deps(),
      dialyzer: [plt_add_apps: [:dummy_app]]
    ]
  end

  def application do
    [applications: [:logger, :public_key]]
  end

  defp deps do
    []
  end
end
