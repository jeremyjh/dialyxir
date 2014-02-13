defmodule Mix.Tasks.Dialyzer do
  use Mix.Task
  alias Mix.Tasks.Dialyzer.Plt, as: Plt

  @shortdoc "Runs dialyzer with default or project-defined flags."

  @moduledoc """
  Runs dialyzer with default flags: 
    -Wunmatched_returns -Werror_handling -Wrace_conditions -Wunderspecs

  You can define a dialyzer_flags key in your Mix project config to override defaults.
  You can also include a dialyzer_paths key to override default path (only Mix.Project.app_path()/ebin)
  
  e.g.
    def project do
      [ app: :my_app,
        version: "0.0.1",
        deps: deps,
        dialyzer: [flags: ["-Werror_handling", "-Wrace_conditions"],
                   paths: ["ebin", "deps/foo/ebin"]]
      ]
    end
  """

  def run(_) do
    IO.puts "Starting Dialyzer"
    cmds = "dialyzer --quiet --no_check_plt --plt #{Plt.plt_file} #{dialyzer_flags} #{dialyzer_paths}"
    IO.puts cmds
    IO.puts System.cmd(cmds)
  end

  import Enum, only: [join: 2]

  defp dialyzer_flags do
    (Mix.project[:dialyzer][:flags]
      || ["-Wunmatched_returns","-Werror_handling","-Wrace_conditions","-Wunderspecs"])
      |> join(" ")
  end

  defp dialyzer_paths, do: (Mix.project[:dialyzer][:paths] || [ Path.join(Mix.Project.app_path, "ebin") ]) |> join(" ")

end

