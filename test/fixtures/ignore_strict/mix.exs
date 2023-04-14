defmodule IgnoreStrict.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ignore_strict,
      version: "0.1.0",
      dialyzer: [
        ignore_warnings: "ignore_strict_test.exs",
        list_unused_filters: true
      ]
    ]
  end
end
