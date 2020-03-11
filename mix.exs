defmodule Dialyxir.Mixfile do
  use Mix.Project

  def project do
    [
      app: :dialyxir,
      version: "1.0.0",
      elixir: ">= 1.6.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: [
        plt_apps: [:dialyzer, :elixir, :kernel, :mix, :stdlib, :erlex],
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
    [mod: {Dialyxir, []}, extra_applications: [:dialyzer, :crypto, :mix]]
  end

  defp description do
    """
    Mix tasks to simplify use of Dialyzer in Elixir projects.
    """
  end

  defp elixirc_paths(:examples), do: ["lib", "test/examples"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:erlex, ">= 0.2.6"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      maintainers: ["Jeremy Huffman"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/jeremyjh/dialyxir"}
    ]
  end
end
