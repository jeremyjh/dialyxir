defmodule Mix.Tasks.Dialyzer do
  @shortdoc "Runs dialyzer with default or project-defined flags."

  @moduledoc """
  Compiles the mix project if needed and runs dialyzer with default flags:
    -Wunmatched_returns -Werror_handling -Wrace_conditions -Wunderspecs

  ## Command line options

    * `--no-compile`       - do not compile even if needed.
    * `--halt-exit-status` - exit immediately with same exit status as dialyzer.
      useful for CI. do not use with `mix do`.

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
    {dargs, halt} = Enum.partition(dargs, &(&1 != "--halt-exit-status"))
    if compile == [], do: Mix.Project.compile([])
    args = List.flatten [dargs, "--no_check_plt", "--plt", "#{Plt.plt_file}", dialyzer_flags, dialyzer_paths]
    puts "Starting Dialyzer"
    puts "dialyzer " <> Enum.join(args, " ")
    {ret, exit_status} = System.cmd("dialyzer", args, [])
    puts ret
    if halt != [] do
      :erlang.halt(exit_status)
    end
  end

  defp dialyzer_flags do
    Mix.Project.config[:dialyzer][:flags]
    || ["-Wunmatched_returns", "-Werror_handling", "-Wrace_conditions", "-Wunderspecs"]
  end

  defp umbrella_childeren_apps do
    (Mix.Project.config[:apps_path] <> "/*/mix.exs")
    |> Path.wildcard
    |> Enum.map(&Path.basename(Path.dirname(&1)))
  end

  defp app_path(app_name) do
    Path.join([Path.relative_to_cwd(Mix.Project.build_path), "lib", app_name, "ebin"])
  end

  defp default_paths(true = _umbrella?) do
    umbrella_childeren_apps
    |> Enum.map(&app_path/1)
  end
  defp default_paths(false = _umbrella?) do
    [ Path.join(Mix.Project.app_path, "ebin") ]
  end

  defp dialyzer_paths do
    Mix.Project.config[:dialyzer][:paths] || default_paths(Mix.Project.umbrella?)
  end
end
