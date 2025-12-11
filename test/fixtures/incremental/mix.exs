defmodule Incremental.Mixfile do
  use Mix.Project

  def project do
    [
      app: :incremental,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        incremental: [
          enabled: true
        ]
      ]
    ]
  end
end
