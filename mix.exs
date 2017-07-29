defmodule Dialyxir.Mixfile do
  use Mix.Project

  def project do
    [
      app: :dialyxir,
      version: "0.5.1",
      elixir: "> 1.3.2",
      description: description(),
      package: package(),
      deps: [ {:ex_doc, ">= 0.0.0", only: :dev} ],
      dialyzer: [ plt_apps: [:dialyzer, :elixir, :kernel, :mix, :stdlib],
                  ignore_warnings: ".dialyzer_ignore",
                  flags: [:unmatched_returns, :error_handling, :underspecs]
                ],

      # Docs
      name: "Dialyxir",
      source_url: "https://github.com/jeremyjh/dialyxir",
      homepage_url: "https://github.com/jeremyjh/dialyxir",
      docs: [main: "readme", # The main page in the docs
             extras: ["README.md"]]
    ]
  end

  def application do
    [applications: [:dialyzer, :crypto, :mix]]
  end

  defp description do
    """
    Mix tasks to simplify use of Dialyzer in Elixir projects.
    """
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Jeremy Huffman"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/jeremyjh/dialyxir"}]
  end
end
