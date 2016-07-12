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

  All configuration is included under a dialyzer key in the project entry.

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

  Includes all project dependencies defined in the mix deps keyword and/or
  the OTP applications list for the project.

      def project do
        [ app: :my_app,
          version: "0.0.1",
          deps: deps,
          dialyzer: plt_add_apps: [:mnesia]
                  , plt_file: ".private.plt"
        ]
      end

  * `dialyzer: :plt_add_apps` - OTP or project dependency applications to include
     *in addition* to the core applications.


  * `dialyzer: :plt_apps` - a list of applications to include that will replace the default,
  include all the apps you need e.g.

      [:erts, :kernel, :stdlib, :mnesia]

  * `dialyzer: :plt_add_deps` - :project - include the project's dependencies in the PLT.
  :transitive - include the full dependency set in the PLT.


      def project do
        [ app: :my_app,
          version: "0.0.1",
          deps: deps,
          dialyzer: plt_add_deps: :transitive
        ]
      end


  * `dialyzer: :plt_file` - specify the plt file name to create and use - default is to use
  a shared PLT in the user's home directory specific to the version of Erlang/Elixir.

  """

  use Mix.Task
  import Dialyxir.Helpers
  import System, only: [user_home!: 0]
  alias Dialyxir.Plt, as: Plt

  def run(args) do
    compatibility_notice()
    {dargs, compile} = Enum.partition(args, &(&1 != "--no-compile"))
    {dargs, halt} = Enum.partition(dargs, &(&1 != "--halt-exit-status"))
    {dargs, no_check} = Enum.partition(dargs, &(&1 != "--no-check"))
    if compile == [], do: Mix.Project.compile([])
    unless no_check != [], do: check_plt()
    args = List.flatten [dargs, "--no_check_plt", "--plt", "#{Plt.deps_plt()}", dialyzer_flags(), dialyzer_paths()]
    dialyze(args, halt)
  end

  defp check_plt() do
    IO.puts "Checking PLT..."
    {apps, hash} = dependency_hash
    if check_hash?(hash) do
      IO.puts "PLT is up to date!"
    else
      Mix.Tasks.Deps.Check.run([]) #compile & load all deps paths
      Mix.Project.compile([]) # compile & load current project paths
      Plt.plts_list(apps) |> Plt.check()
      File.write(plt_hash_file, hash)
    end
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

  defp default_paths() do
    reduce_umbrella_children([], fn(paths) ->
      [Mix.Project.compile_path | paths]
    end)
  end

  defp dialyzer_paths do
    Mix.Project.config[:dialyzer][:paths] || default_paths()
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

    @spec check_hash?(binary()) :: boolean()
  defp check_hash?(hash) do
	  case File.read(plt_hash_file) do
      {:ok, stored_hash} -> hash == stored_hash
      _ -> false
    end
  end

  defp plt_hash_file do
	  Plt.deps_plt() <> ".hash"
  end

  @spec dependency_hash :: {[atom()], binary()}
  def dependency_hash do
    lock_file = Mix.Dep.Lock.read |> :erlang.term_to_binary
    apps = cons_apps
    hash = :crypto.hash(:sha, lock_file <> :erlang.term_to_binary(apps))
    {apps, hash}
  end

  defp cons_apps, do: (plt_apps() || (plt_add_apps() ++ include_deps()))

  defp plt_apps, do: Mix.Project.config[:dialyzer][:plt_apps] |> load_apps()
  defp plt_add_apps, do: Mix.Project.config[:dialyzer][:plt_add_apps] || [] |> load_apps()
  defp load_apps(apps) do
    if apps do
      Enum.map(apps, &Application.load/1)
      apps
    end
  end

  defp include_deps do
    method = Mix.Project.config[:dialyzer][:plt_add_deps]
    reduce_umbrella_children([],fn(deps) ->
      deps ++ case method do
        false    -> []
        true     -> deps_project() #compatibility
        :project -> deps_project()
        _        -> deps_transitive()
      end
    end) |> Enum.sort |> Enum.uniq |> IO.inspect
  end

  defp deps_project do
    deps = Mix.Project.config[:deps]
              |> Enum.filter(&env_dep(&1))
              |> Enum.map(&elem(&1,0))
    deps_app(false) ++ deps
  end
  defp deps_transitive do
    deps = (Mix.Project.deps_paths
              |> Map.keys)
    deps_app(true) ++ deps
  end

  @spec deps_app(boolean()) :: [atom]
  defp deps_app(recursive) do
    app = Keyword.fetch!(Mix.Project.config(), :app)
    deps_app(app, recursive)
  end
  @spec deps_app(atom(), boolean()) :: [atom]
  defp deps_app(app, recursive) do
    with_each = if recursive do
                  &deps_app(&1,true)
                else
                  fn _ -> [] end
                end
    Application.load(app)
    case Application.spec(app, :applications) do
      []        -> []
      nil       -> []
      this_apps ->
        Enum.map(this_apps, with_each)
        |> List.flatten
        |> Enum.concat(this_apps)
    end
  end


  defp env_dep(dep) do
    only_envs = dep_only(dep)
    only_envs == nil || Mix.env in List.wrap(only_envs)
  end
  defp dep_only({_, opts}) when is_list(opts), do: opts[:only]
  defp dep_only({_, _, opts}) when is_list(opts), do: opts[:only]
  defp dep_only(_), do: nil

  @spec reduce_umbrella_children(a, (a -> a)) :: a when a: term()
  defp reduce_umbrella_children(acc,f) do
    if Mix.Project.umbrella? do
      children = Mix.Dep.Umbrella.loaded
      Enum.reduce(children, acc,
        fn(child, acc) ->
          Mix.Project.in_project(child.app, child.opts[:path],
                                 fn _ -> reduce_umbrella_children(acc,f) end)
        end)
    else
      f.(acc)
    end
  end
end
