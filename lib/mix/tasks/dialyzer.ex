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

  All configuration is included under a dialyzer key in the mix project keyword list.

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

  ## PLT Configuration

  The task will build a PLT with default core Erlang applications: erts kernel stdlib crypto
  It also includes all modules in the Elixir standard library.

  By default the PLT includes all project dependencies defined in the mix deps keyword and/or
  the OTP applications list for the project but this can be configured.

      def project do
        [ app: :my_app,
          version: "0.0.1",
          deps: deps,
          dialyzer: plt_add_apps: [:mnesia]
                  , plt_file: ".private.plt"
        ]
      end

  * `dialyzer: :plt_add_apps` - applications to include
     *in addition* to the core applications and project dependencies.


  * `dialyzer: :plt_apps` - a list of applications to include that will replace the default,
  include all the apps you need e.g.

      [:erts, :kernel, :stdlib, :mnesia]

  * `dialyzer: :plt_add_deps` - controls which dependencies are added to the PLT - defaults to :apps_tree. In all cases the dependency list is recurisvely built for mix umbrella projects.
       *  :transitive - include the full dependency tree (from mix deps and applications) in the PLT.
       *  :project - include the project's direct dependencies (from mix deps and applications) in the PLT.
       *  :apps_tree - include the full OTP application dependency tree (`mix app.tree`) but not the mix dependencies.
       *  :apps_direct - include only the direct OTP application dependencies for the app(s) in the mix project.
       *  :false - do not include any dependencies in the project PLT (you'll need to specify your dependencies with a plt_add_apps key).


      def project do
        [ app: :my_app,
          version: "0.0.1",
          deps: deps,
          dialyzer: [plt_add_deps: :apps_direct]
        ]
      end


  * `dialyzer: :plt_file` - Deprecated - specify the plt file name to create and use - default is to create one in the project's current build environmnet (e.g. _build/dev/) specific to the Erlang/Elixir version used. Note that use of this key in version 0.4 or later will produce a deprecation warning - you can silence the warning by providing a pair with key :no_warn e.g. `plt_file: {:no_warn,"filename"}`.

  * `dialyzer: :plt_core_path` - specify an alternative to MIX_HOME to use to store the Erlang and Elixir core files.
  """

  use Mix.Task
  import Dialyxir.Helpers
  import System, only: [user_home!: 0]
  alias Dialyxir.Project
  alias Dialyxir.Plt

  def run(args) do
    check_dialyzer()
    compatibility_notice()
    Project.check_config()
    {dargs, compile} = Enum.partition(args, &(&1 != "--no-compile"))
    {dargs, halt} = Enum.partition(dargs, &(&1 != "--halt-exit-status"))
    {dargs, no_check} = Enum.partition(dargs, &(&1 != "--no-check"))
    no_check = if in_child? do
                  IO.puts "In an Umbrella child, not checking PLT..."
                  ["--no-check"]
               else
                 no_check
               end
    if compile == [], do: Mix.Project.compile([])
    unless no_check != [], do: check_plt()
    args = List.flatten [dargs, "--no_check_plt", "--plt", "#{Project.plt_file()}", dialyzer_flags(), Project.dialyzer_paths()]
    dialyze(args, halt)
  end

  defp check_plt() do
    IO.puts "Checking PLT..."
    {apps, hash} = dependency_hash
    if check_hash?(hash) do
      IO.puts "PLT is up to date!"
    else
      Project.plts_list(apps) |> Plt.check()
      File.write(plt_hash_file, hash)
    end
  end

  defp in_child? do
    String.contains?(Mix.Project.config[:lockfile], "..")
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

  defp check_dialyzer do
    if not Code.ensure_loaded?(:dialyzer) do
       IO.puts """
       DEPENDENCY MISSING
       ------------------------
       If you are reading this message, then Elixir and Erlang are installed but the
       Erlang Dialyzer is not available. Probably this is because you installed Erlang
       with your OS package manager and the Dialyzer package is separate.

       On Debian/Ubuntu:

         `apt-get install erlang-dialyzer`

       Fedora:

          `yum install erlang-dialyzer`

       Arch and Homebrew include Dialyzer in their base erlang packages. Please report a Github
       issue to add or correct distribution-specific information.
       """
       :erlang.halt(3)
    end

  end

  defp compatibility_notice do
    old_plt = "#{user_home!()}/.dialyxir_core_*.plt"
    if File.exists?(old_plt) && (!File.exists?(Project.erlang_plt()) || !File.exists?(Project.elixir_plt())) do

      puts """
      COMPATIBILITY NOTICE
      ------------------------
      Previous usage of a pre-0.4 version of Dialyxir detected. Please be aware that the 0.4 release
      makes a number of changes to previous defaults. Among other things, the PLT task is automatically
      run when dialyzer is run, PLT paths have changed,
      transitive dependencies are included by default in the PLT, and no additional warning flags
      beyond the dialyzer defaults are included. All these properties can be changed in configuration.
      (see `mix help dialyzer`).

      If you no longer use the older Dialyxir in any projects and do not want to see this notice each time you upgrade your Erlang/Elixir distribution, you can delete your old pre-0.4 PLT files. ( rm ~/.dialyxir_core_*.plt )
      """
    end
  end

  @spec check_hash?(binary()) :: boolean()
  defp check_hash?(hash) do
	  case File.read(plt_hash_file) do
      {:ok, stored_hash} -> hash == stored_hash
      _ -> false
    end
  end

  defp plt_hash_file, do: Project.plt_file() <> ".hash"

  @spec dependency_hash :: {[atom()], binary()}
  def dependency_hash do
    lock_file = Mix.Dep.Lock.read |> :erlang.term_to_binary
    apps = Project.cons_apps |> IO.inspect
    hash = :crypto.hash(:sha, lock_file <> :erlang.term_to_binary(apps))
    {apps, hash}
  end

end
