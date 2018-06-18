defmodule Dialyxir.Mixfile do
  use Mix.Project

  def project do
    [
      app: :dialyxir,
      version: "1.0.0-rc.2",
      elixir: ">= 1.6.0",
      description: description(),
      package: package(),
      deps: [{:ex_doc, ">= 0.0.0", only: :dev}],
      dialyzer: [
        plt_apps: [:dialyzer, :elixir, :kernel, :mix, :stdlib],
        ignore_warnings: ".dialyzer_ignore.exs",
        flags: [:unmatched_returns, :error_handling, :underspecs]
      ],
      # Docs
      name: "Dialyxir",
      source_url: "https://github.com/jeremyjh/dialyxir",
      homepage_url: "https://github.com/jeremyjh/dialyxir",
      # The main page in the docs
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application do
    [mod: {Dialyxir, []}, applications: [:dialyzer, :crypto, :mix]]
  end

  defp description do
    """
    Mix tasks to simplify use of Dialyzer in Elixir projects.
    """
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE",
        "src/dialyzer_lexer.xrl",
        "src/dialyzer_parser.yrl"
      ],
      maintainers: ["Jeremy Huffman"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/jeremyjh/dialyxir"}
    ]
  end
end
