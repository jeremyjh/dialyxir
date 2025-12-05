defmodule IncrementalCustomPlt.Mixfile do
  use Mix.Project

  def project do
    [
      app: :incremental_custom_plt,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: true,
        plt_incremental_file: "custom_incremental.plt"
      ]
    ]
  end
end
