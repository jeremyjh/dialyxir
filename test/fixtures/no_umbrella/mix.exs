defmodule NoUmbrella.Mixfile do
  use Mix.Project

  def project do
    [
      app: :no_umbrella,
      prune_code_paths: false,
      version: "0.1.0",
      lockfile: "../mix.lock",
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: [],
      dialyzer: [no_umbrella: true]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :public_key]]
  end
end
