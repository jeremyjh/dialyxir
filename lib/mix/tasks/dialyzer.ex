defmodule Mix.Tasks.Dialyzer do
  @shortdoc "Runs dialyzer with default or project-defined flags."

  @moduledoc """
  This task compiles the mix project, creates a PLT with dependencies if needed and runs `dialyzer`. Much of its behavior can be managed in configuration as described below.

  If executed outside of a mix project, it will build the core PLT files and exit.

  ## Command line options

    * `--no-compile`       - do not compile even if needed.
    * `--no-check`         - do not perform (quick) check to see if PLT needs updated.
    * `--halt-exit-status` - exit immediately with same exit status as dialyzer.
      useful for CI. do not use with `mix do`.
    * `--plt`              - only build the required plt(s) and exit.

  Warning flags passed to this task are passed on to `:dialyzer`.

  e.g.
  `mix dialyzer --unmatched_returns`

  ## Configuration

  All configuration is included under a dialyzer key in the mix project keyword list.

  ### Flags

  You can specify any `dialyzer` command line argument with the :flags keyword.

  Dialyzer supports a number of warning flags used to enable or disable certain kinds of analysis features. Until version 0.4, `dialyxir` used by default the additional warning flags shown in the example below. However some of these create warnings that are often more confusing than helpful, particularly to new users of Dialyzer. As of 0.4, there are no longer any flags used by default. To get the old behavior, specify them in your Mix project file. For compatibility reasons you can use eiher the `-Wwarning` convention of the dialyzer CLI, or (preferred) the `WarnOpts` atoms supported by the [API](http://erlang.org/doc/man/dialyzer.html#gui-1).  e.g.

  ```elixir
  def project do
  [ app: :my_app,
  version: "0.0.1",
  deps: deps,
  dialyzer: [ flags: ["-Wunmatched_returns", :error_handling, :underspecs]]
  ]
  end
  ```

  ### PLT Configuration

  The task will build a PLT with default core Erlang applications: `:erts :kernel :stdlib :crypto` and re-use this core file in multiple projects - another core file is created for Elixir.

  OTP application dependencies are (transitively) added to your project's PLT by default. The applications added are the same as you would see displayed with the command `mix app.tree`. There is also a `:plt_add_deps` option you can set to control the dependencies added. The following options are supported:

  * :project - Direct Mix and OTP dependencies
  * :apps_direct - Only Direct OTP application dependencies - not the entire tree
  * :transitive - Include Mix and OTP application dependencies recursively
  * :app_tree - Transitive OTP application dependencies e.g. `mix app.tree` (default)

  ```
  def project do
    [ app: :my_app,
    version: "0.0.1",
    deps: deps,
    dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: :wx]
    ]
  end
  ```

  You can also configure applications to include in the PLT more directly:

  * `dialyzer: :plt_add_apps` - applications to include
  *in addition* to the core applications and project dependencies.

  * `dialyzer: :plt_apps` - a list of applications to include that will replace the default,
  include all the apps you need e.g.

  ### Other Configuration

  * `dialyzer: :plt_file` - Deprecated - specify the plt file name to create and use - default is to create one in the project's current build environmnet (e.g. _build/dev/) specific to the Erlang/Elixir version used. Note that use of this key in version 0.4 or later will produce a deprecation warning - you can silence the warning by providing a pair with key :no_warn e.g. `plt_file: {:no_warn,"filename"}`.

  * `dialyzer: :plt_core_path` - specify an alternative to MIX_HOME to use to store the Erlang and Elixir core files.

  * `dialyzer: :ignore_warnings` - specify file path to filter well-known warnings.
  """

  use Mix.Task
  import System, only: [user_home!: 0]
  alias Dialyxir.Project
  alias Dialyxir.Plt
  alias Dialyxir.Dialyzer

  @default_warnings [ :unknown ]
  @command_options [ no_compile: :boolean,
                     no_check: :boolean,
                     halt_exit_status: :boolean,
                     plt: :boolean ]

  def run(args) do
    check_dialyzer()
    compatibility_notice()
    if Mix.Project.get() do
      Project.check_config()

      {opts, _, dargs} = OptionParser.parse(args, strict: @command_options)

      unless opts[:no_compile], do: Mix.Project.compile([])
      _ = unless no_check?(opts), do: check_plt()
      unless opts[:plt], do: run_dialyzer(opts, dargs)
    else
      IO.puts "No mix project found - checking core PLTs..."
      Project.plts_list([], false) |> Plt.check()
    end
  end

  defp no_check?(opts) do
    case {in_child?(), no_plt?()} do
      {true, true} ->
        IO.puts "In an Umbrella child and no PLT found - building that first."
        build_parent_plt()
        true
      {true, false} ->
        IO.puts "In an Umbrella child, not checking PLT..."
        true
      _ -> opts[:no_check]
    end
  end

  defp check_plt() do
    IO.puts "Checking PLT..."
    {apps, hash} = dependency_hash()
    if check_hash?(hash) do
      IO.puts "PLT is up to date!"
    else
      Project.plts_list(apps) |> Plt.check()
      File.write(plt_hash_file(), hash)
    end
  end

  defp run_dialyzer(opts, dargs) do
    args = [ { :check_plt, false },
             { :init_plt, String.to_charlist(Project.plt_file()) },
             { :files_rec, Project.dialyzer_paths() },
             { :warnings, dialyzer_warnings(dargs) } ]

    IO.puts "Starting Dialyzer"
    IO.inspect args, label: "dialyzer args"
    { _, exit_status, result } = Dialyzer.dialyze(args)
    Enum.each(result, &IO.puts/1)
    if opts[:halt_exit_status], do: :erlang.halt(exit_status)
  end

  defp dialyzer_warnings(dargs) do
    raw_opts = Project.dialyzer_flags() ++ Enum.map(dargs, &elem(&1,0))
    transform(raw_opts) ++ @default_warnings -- Project.dialyzer_removed_defaults()
  end

  defp transform(options) when is_list(options), do: Enum.map(options, &transform/1)
  defp transform(option) when is_atom(option), do: option
  defp transform(option) when is_binary(option) do
    option
    |> String.replace_leading("-W", "")
    |> String.replace("--", "")
    |> String.to_atom()
  end


  defp in_child? do
    String.contains?(Mix.Project.config[:lockfile], "..")
  end

  defp no_plt? do
    not File.exists?(Project.deps_plt())
  end

  defp build_parent_plt() do
    parent = Mix.Project.config[:lockfile] |> Path.expand |> Path.dirname
    opts = [ into: IO.stream(:stdio, :line),
             stderr_to_stdout: true,
             cd: parent ]
    # It would seem more natural to use Mix.in_project here to start in our parent project.
    # However part of the app.tree resolution includes loading all sub apps, and we will
    # hit an exception when we try to do that for *this* child, which is already loaded.
    {out, rc} = System.cmd("mix", ["dialyzer", "--plt"], opts)
    if rc != 0 do
      IO.puts("Error building parent PLT, process returned code: #{rc}\n#{out}")
    end
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

      IO.puts """
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
	  case File.read(plt_hash_file()) do
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
