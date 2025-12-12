defmodule IncrementalAbsolutePath.Mixfile do
  use Mix.Project

  def project do
    [
      app: :incremental_absolute_path,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: [
          enabled: true
        ],
        plt_incremental_file: "_build/test/absolute_incremental.plt"
      ]
    ]
  end
end
