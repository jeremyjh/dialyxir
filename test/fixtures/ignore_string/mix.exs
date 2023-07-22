defmodule IgnoreString.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ignore_string,
      version: "0.1.0",
      prune_code_paths: false,
      dialyzer: [
        ignore_warnings: "dialyzer.ignore-warnings",
        list_unused_filters: true
      ]
    ]
  end
end
