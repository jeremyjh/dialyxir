defmodule IgnoreCustomEmpty.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ignore_custom_empty,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        # this file is expected to not exist
        ignore_warnings: "ignore_test.exs",
        list_unused_filters: true
      ]
    ]
  end
end
