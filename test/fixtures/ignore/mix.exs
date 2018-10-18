defmodule Ignore.Mixfile do
  use Mix.Project

  def project do
    [app: :ignore, version: "0.1.0", dialyzer: [ignore_warnings: "ignore_test.exs"]]
  end
end
