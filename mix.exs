defmodule Dialyxir.Mixfile do
  use Mix.Project

  def project do
    [
      app: :dialyxir,
      version: "0.3.5",
      elixir: "~> 1.0",
      description: description,
      package: package,
      deps: []
    ]
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
