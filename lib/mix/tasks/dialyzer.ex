defmodule Mix.Tasks.Dialyzer do
  @shortdoc "Runs dialyzer with default or project-defined flags."

  @moduledoc """
  Compiles the mix project if needed and runs dialyzer with default flags:
    -Wunmatched_returns -Werror_handling -Wrace_conditions -Wunderspecs

  ## Command line options

    * `--no-compile`       - do not compile even if needed.
    * `--no-check`         - do not perform (quick) check to see if PLT needs updated.
    * `--halt-exit-status` - exit immediately with same exit status as dialyzer.
      useful for CI. do not use with `mix do`.

  Any other arguments passed to this task are passed on to the dialyzer command.

  e.g.
    mix dialyzer --raw

  ## Configuration

  You can define a dialyzer: :flags key in your Mix project Keywords to provide additional args (such as optional warnings).
  You can include a dialyzer: :paths key to override paths of beam files you want to analyze (defaults to Mix.project.app_path()/ebin)

  e.g.
    def project do
      [ app: :my_app,
        version: "0.0.1",
        deps: deps,
        dialyzer: [flags: ["-Wunmatched_returns"],
                   paths: ["ebin", "deps/foo/ebin"]]
      ]
    end


  """

  use Mix.Task
  import Dialyxir.Helpers
  import System, only: [user_home!: 0]
  alias Dialyxir.Plt, as: Plt

  def run(args) do
    {dargs, compile} = Enum.partition(args, &(&1 != "--no-compile"))
    {dargs, halt} = Enum.partition(dargs, &(&1 != "--halt-exit-status"))
    {dargs, no_check} = Enum.partition(dargs, &(&1 != "--no-check"))
    if compile == [], do: Mix.Project.compile([])
    args = List.flatten [dargs, "--no_check_plt", "--plt", "#{Plt.deps_plt()}", dialyzer_flags(), dialyzer_paths()]
    compatibility_notice()
    unless no_check, do: Mix.Tasks.Dialyzer.Plt.run([])
    dialyze(args, halt)
  end

  defp dialyze(args, halt) do
    puts "Starting Dialyzer"
    puts "dialyzer " <> Enum.join(args, " ")
    {ret, exit_status} = System.cmd("dialyzer", args, [])
    puts ret
    if halt != [] do
      :erlang.halt(exit_status)
    end
  end

  defp dialyzer_flags do
    Mix.Project.config[:dialyzer][:flags] || []
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
    umbrella_childeren_apps()
    |> Enum.map(&app_path/1)
  end
  defp default_paths(false = _umbrella?) do
    [ Path.join(Mix.Project.app_path, "ebin") ]
  end

  defp dialyzer_paths do
    Mix.Project.config[:dialyzer][:paths] || default_paths(Mix.Project.umbrella?)
  end

  defp compatibility_notice do
    old_plt = "#{user_home!()}/.dialyxir_core_*.plt"
    if File.exists?(old_plt) && (!File.exists?(Plt.erlang_plt()) || !File.exists?(Plt.elixir_plt())) do

      puts """
      COMPATIBILITY NOTICE
      ------------------------
      Previous usage of a pre-0.4 version of Dialyxir detected. Please be aware that the 0.4 release
      makes a number of changes to previous defaults. Among other things, the PLT task is automatically
      run when dialyzer is run, PLT paths have changed,
      transitive dependencies are included by default in the PLT, and no additional warning flags
      beyond the dialyzer defaults are included. All these properties can be changed in configuration.
      (see `mix help dialyzer` and `mix help dialyzer.plt`).
      """
    end
  end
end
