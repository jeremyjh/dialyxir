defmodule Umbrella.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      prune_code_paths: false,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end
end
