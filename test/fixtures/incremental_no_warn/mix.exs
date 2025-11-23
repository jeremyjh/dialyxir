defmodule IncrementalNoWarn.Mixfile do
  use Mix.Project

  def project do
    [
      app: :incremental_no_warn,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: true,
        plt_incremental_file: {:no_warn, "incremental_no_warn.plt"}
      ]
    ]
  end
end
