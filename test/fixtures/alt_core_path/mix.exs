defmodule AltCorePath.Mixfile do
  use Mix.Project

  def project do
    [
      app: :alt_core_path,
      prune_code_paths: false,
      version: "1.0.0",
      dialyzer: [plt_core_path: "_build"]
    ]
  end
end
