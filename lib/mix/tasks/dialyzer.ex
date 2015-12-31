defmodule Mix.Tasks.Dialyzer do
  @shortdoc "Runs dialyzer with default or project-defined flags."

  @moduledoc """
  Compiles the mix project if needed and runs dialyzer with default flags:
    -Wunmatched_returns -Werror_handling -Wrace_conditions -Wunderspecs

  ## Command line options

    * `--no-compile`      - do not compile even if needed.

  Any other arguments passed to this task are passed on to the dialyzer command.

  e.g.
    mix dialyzer --raw

  ## Configuration

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

  use Mix.Task
  alias Mix.Tasks.Dialyzer.Plt, as: Plt
  import Dialyxir.Helpers

  def run(args) do
    {dargs, compile} = Enum.partition(args, &(&1 != "--no-compile"))
    if compile == [], do: Mix.Project.compile([])
    args = List.flatten [dargs, "--no_check_plt", "--plt", "#{Plt.plt_file}", dialyzer_flags, dialyzer_paths]
    puts "Starting Dialyzer"
    puts "dialyzer " <> Enum.join(args, " ")
    {ret, _} = System.cmd("dialyzer", args, [])
    puts ret
  end

  defp dialyzer_flags do
    Mix.Project.config[:dialyzer][:flags]
    || ["-Wunmatched_returns", "-Werror_handling", "-Wrace_conditions", "-Wunderspecs"]
  end

  defp dialyzer_paths do
    Mix.Project.config[:dialyzer][:paths] || [ Path.join(Mix.Project.app_path, "ebin") ]
  end
end
