defmodule Dialyxir.Mixfile do
  use Mix.Project

  def project do
    [ app: :dialyxir,
      version: "0.2.4",
      elixir: ">= 0.13.3",
      deps: deps
    ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    []
  end

end
defmodule Mix.Tasks.Install do
  use Mix.Task
  @shortdoc "Locally install the Dialyxir task archive."

  def run(_) do
    case Code.ensure_loaded(Mix.Archive) do
      {:module, _} -> do_install
      {:error, _} -> do_old_install
    end
  end

  defp do_install do
      Mix.Tasks.Archive.run []
      Mix.Tasks.Local.Install.run ["--force"]
  end

  defp do_old_install do
    cmds = "echo 'y' | mix local.install ebin/Elixir.Mix.Tasks.Dialyzer.beam"
    IO.puts cmds
    IO.puts System.cmd(cmds)

    cmds = "echo 'y' | mix local.install ebin/Elixir.Mix.Tasks.Dialyzer.Plt.beam"
    IO.puts cmds
    IO.puts System.cmd(cmds)
  end
end
