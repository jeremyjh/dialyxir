defmodule Ignore.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ignore,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        list_unused_filters: true
      ]
    ]
  end
end
