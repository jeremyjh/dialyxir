defmodule Ignore.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ignore,
      version: "0.1.0",
      dialyzer: [
        ignore_warnings: "ignore_strict_test.exs",
        list_unused_filters: true
      ]
    ]
  end
end
