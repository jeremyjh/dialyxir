defmodule Mix.Tasks.Dialyzer do
  @shortdoc "Runs dialyzer with default or project-defined flags."

  @moduledoc """
  This task compiles the mix project, creates a PLT with dependencies if needed and runs `dialyzer`. Much of its behavior can be managed in configuration as described below.

  If executed outside of a mix project, it will build the core PLT files and exit.

  ## Command line options

    * `--no-compile` - do not compile even if needed
    * `--no-check` - do not perform (quick) check to see if PLT needs update
    * `--force-check` - force PLT check also if lock file is unchanged useful
      when dealing with local deps.
    * `--ignore-exit-status` - display warnings but do not halt the VM or
      return an exit status code
    * `--incremental` - enable incremental mode (requires OTP 26+). Overrides
      the `incremental` setting in mix.exs if present.
    * `--apps <app1,app2,...>` - specify applications to analyze (requires --incremental).
      Multiple apps can be comma-separated or the flag can be used multiple times.
      These are typically OTP and third-party libraries that Dialyzer needs to understand
      but where you don't want warnings reported.
    * `--warning-apps <app1,app2,...>` - specify applications to emit warnings for (requires --incremental).
      Multiple apps can be comma-separated or the flag can be used multiple times.
      These are typically your own applications where you want warnings reported.
      Note: `--apps` and `--warning-apps` must not overlap - they are mutually exclusive.
    * `--list-unused-filters` - list unused ignore filters useful for CI. do
      not use with `mix do`.
    * `--plt` - only build the required PLT(s) and exit
    * `--format <name>`        - Specify the format for the warnings, can be specified multiple times to print warnings multiple times in different output formats. Defaults to `dialyxir`.
      * `--format short`       - format the warnings in a compact format, suitable for ignore file using Elixir term format.
      * `--format raw`         - format the warnings in format returned before Dialyzer formatting
      * `--format dialyxir`    - format the warnings in a pretty printed format (default)
      * `--format dialyzer`    - format the warnings in the original Dialyzer format
      * `--format github`      - format the warnings in the Github Actions message format
      * `--format ignore_file` - format the warnings in {file, warning} format for Elixir Format ignore file
      * `--format ignore_file_strict` - format the warnings in {file, short_description} format for Elixir Format ignore file.
    * `--quiet` - suppress all informational messages
    * `--quiet-with-result` - suppress all informational messages except for the final result message

  Warning flags passed to this task are passed on to `:dialyzer` - e.g.

      mix dialyzer --unmatched_returns

  ## Configuration

  All configuration is included under a dialyzer key in the mix project keyword list.

  ### Flags

  You can specify any `dialyzer` command line argument with the :flags keyword.

  Dialyzer supports a number of warning flags used to enable or disable certain kinds of analysis features. Until version 0.4, `dialyxir` used by default the additional warning flags shown in the example below. However some of these create warnings that are often more confusing than helpful, particularly to new users of Dialyzer. As of 0.4, there are no longer any flags used by default. To get the old behavior, specify them in your Mix project file. For compatibility reasons you can use either the `-Wwarning` convention of the dialyzer CLI, or (preferred) the `WarnOpts` atoms supported by the [API](http://erlang.org/doc/man/dialyzer.html#gui-1).  e.g.

  ```elixir
  def project do
    [
      app: :my_app,
      version: "0.0.1",
      deps: deps,
      dialyzer: [flags: ["-Wunmatched_returns", :error_handling, :underspecs]]
    ]
  end
  ```

  ### PLT Configuration

  The task will build a PLT with default core Erlang applications: `:erts :kernel :stdlib :crypto` and re-use this core file in multiple projects - another core file is created for Elixir.

  OTP application dependencies are (transitively) added to your project's PLT by default. The applications added are the same as you would see displayed with the command `mix app.tree`. There is also a `:plt_add_deps` option you can set to control the dependencies added. The following options are supported:

  * `:apps_direct` - Only Direct OTP runtime application dependencies - not the entire tree
  * `:app_tree` - Transitive OTP runtime application dependencies e.g. `mix app.tree` (default)

  ```
  def project do
    [
      app: :my_app,
      version: "0.0.1",
      deps: deps,
      dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: [:wx]]
    ]
  end
  ```

  You can also configure applications to include in the PLT more directly:

  * `dialyzer: :plt_add_apps` - applications to include
  *in addition* to the core applications and project dependencies.

  * `dialyzer: :plt_ignore_apps` - applications to ignore from the list of core
  applications and dependencies.

  * `dialyzer: :plt_apps` - a list of applications to include that will replace the default,
  include all the apps you need e.g.

  ### Other Configuration

  * `dialyzer: :plt_file` - Deprecated - specify the PLT file name to create and use - default is to create one in the project's current build environment (e.g. _build/dev/) specific to the Erlang/Elixir version used. Note that use of this key in version 0.4 or later will produce a deprecation warning - you can silence the warning by providing a pair with key :no_warn e.g. `plt_file: {:no_warn,"filename"}`.

  * `dialyzer: :plt_local_path` - specify the PLT directory name to create and use - default is the project's current build environment (e.g. `_build/dev/`).

  * `dialyzer: :plt_core_path` - specify an alternative to `MIX_HOME` to use to store the Erlang and Elixir core files.

  * `dialyzer: :ignore_warnings` - specify file path to filter well-known warnings.

  ### Incremental Mode

  * `dialyzer: :incremental` - enable Dialyzer's incremental analysis mode (requires OTP 26+). When set to `true`, Dialyzer will reuse previous analysis results and analyze changed modules plus any modules that depend on them, significantly speeding up subsequent runs. Note that incremental PLT files are separate from standard PLTs and are managed by Dialyzer itself.

  * `dialyzer: :core_apps` - list of core OTP applications to include when using `apps: :transitive` or `warning_apps: :transitive`. Defaults to an empty list if not specified. This is useful for specifying which core OTP apps (like `:erts`, `:kernel`, `:stdlib`, `:elixir`, `:logger`, `:mix`) should be included in the analysis.

  * `dialyzer: :apps` - applications to analyze (requires incremental: true). These are
    typically OTP and third-party libraries that Dialyzer needs to understand but where you don't
    want warnings reported. Can be:
    - An explicit list: `[:erts, :kernel, :stdlib, ...]`
    - `:transitive` - automatically includes `core_apps` + all dependencies + project apps
    - `:project` - automatically includes only project apps (umbrella children or single app)
    - `nil` - file mode (no app mode)

  * `dialyzer: :warning_apps` - applications to emit warnings for (requires incremental: true).
    These are typically your own applications where you want warnings reported. Can be:
    - An explicit list: `[:my_app, :other_app]`
    - `:transitive` - automatically includes `core_apps` + all dependencies + project apps
    - `:project` - automatically includes only project apps (umbrella children or single app)
    - `nil` - no warning apps

  Note: `apps` and `warning_apps` must not overlap - they are mutually exclusive.

  ```elixir
  # Using explicit lists (backward compatible)
  def project do
    [
      app: :my_app,
      version: "0.0.1",
      deps: deps,
      dialyzer: [
        incremental: true,
        apps: [:erts, :kernel, :stdlib, :elixir, :logger],
        warning_apps: [:my_app]
      ]
    ]
  end

  # Using flags for automatic resolution
  def project do
    [
      app: :my_app,
      version: "0.0.1",
      deps: deps,
      dialyzer: [
        incremental: true,
        core_apps: [:erts, :kernel, :stdlib, :crypto, :elixir, :logger, :mix],
        apps: :transitive,  # Resolves to core_apps ++ deps ++ project_apps
        warning_apps: :project  # Resolves to project apps only
      ]
    ]
  end
  ```
  """

  use Mix.Task
  import System, only: [user_home!: 0]
  import Dialyxir.Output
  alias Dialyxir.Project
  alias Dialyxir.Plt
  alias Dialyxir.Dialyzer

  defmodule Build do
    @shortdoc "Build the required PLT(s) and exit."

    @moduledoc """
    This task compiles the mix project and creates a PLT with dependencies if needed.
    It is equivalent to running `mix dialyzer --plt`

    ## Command line options

    * `--no-compile` - do not compile even if needed.
    """
    use Mix.Task

    def run(args) do
      Mix.Tasks.Dialyzer.run(["--plt" | args])
    end
  end

  defmodule Clean do
    @shortdoc "Delete PLT(s) and exit."

    @moduledoc """
    This task deletes PLT files and hash files.

    ## Command line options

      * `--all` - delete also core PLTs.
    """
    use Mix.Task

    @command_options [all: :boolean]
    def run(args) do
      {opts, _, _dargs} = OptionParser.parse(args, strict: @command_options)
      Mix.Tasks.Dialyzer.clean(opts)
    end
  end

  @default_warnings [:unknown]

  @old_options [
    halt_exit_status: :boolean
  ]

  @command_options Keyword.merge(@old_options,
                     force_check: :boolean,
                     ignore_exit_status: :boolean,
                     incremental: :boolean,
                     list_unused_filters: :boolean,
                     no_check: :boolean,
                     no_compile: :boolean,
                     plt: :boolean,
                     quiet: :boolean,
                     quiet_with_result: :boolean,
                     raw: :boolean,
                     format: [:string, :keep],
                     apps: :keep,
                     warning_apps: :keep
                   )

  def run(args) do
    {opts, _, dargs} = OptionParser.parse(args, strict: @command_options)
    original_shell = Mix.shell()
    if opts[:quiet] || opts[:quiet_with_result], do: Mix.shell(Mix.Shell.Quiet)
    opts = Keyword.delete(opts, :quiet)
    check_dialyzer()
    compatibility_notice()

    if Mix.Project.get() do
      Project.check_config()

      incremental? = resolve_incremental(opts[:incremental])
      opts = Keyword.put(opts, :incremental, incremental?)

      apps = parse_apps_list(opts, :apps)
      warning_apps = parse_apps_list(opts, :warning_apps)

      # Validate that apps/warning_apps are only used with incremental
      if (apps != [] || warning_apps != []) && !incremental? do
        error("""
        --apps and --warning-apps can only be used with --incremental
        """)

        exit(1)
      end

      # Merge CLI values with config values (CLI takes precedence)
      config_apps = Dialyxir.Project.dialyzer_apps()
      config_warning_apps = Dialyxir.Project.dialyzer_warning_apps()

      # If incremental is false but apps/warning_apps CLI flags are provided, ignore them and use config
      final_apps =
        if !incremental? && apps != [] do
          normalize_apps(config_apps)
        else
          if apps == [], do: normalize_apps(config_apps), else: normalize_apps(apps)
        end

      final_warning_apps =
        if !incremental? && warning_apps != [] do
          normalize_apps(config_warning_apps)
        else
          if warning_apps == [],
            do: normalize_apps(config_warning_apps),
            else: normalize_apps(warning_apps)
        end

      # Ensure warning_apps are included in apps (warning_apps must be a subset of apps)
      # This ensures Dialyzer analyzes all apps, but only reports warnings for warning_apps
      # We automatically merge warning_apps into apps so they're always included
      final_apps =
        if incremental? && final_warning_apps != [] do
          (final_apps ++ final_warning_apps) |> Enum.uniq()
        else
          final_apps
        end

      # Filter out missing apps and warn about them
      final_apps = filter_missing_apps(final_apps, "apps")
      final_warning_apps = filter_missing_apps(final_warning_apps, "warning_apps")

      unless opts[:no_compile], do: Mix.Task.run("compile")

      no_check = no_check?(opts)
      skip_plt_check? = incremental? && !opts[:plt]

      cond do
        no_check ->
          :ok

        skip_plt_check? ->
          info("Incremental mode enabled; skipping PLT check step")
          info("Will use PLT file: #{Project.plt_file(true)}")

        incremental? && opts[:plt] ->
          info("""
          Incremental mode is enabled. The --plt flag builds classic PLTs, but incremental mode uses PLTs managed by Dialyzer itself.
          Skipping classic PLT build. Run 'mix dialyzer --incremental' to let Dialyzer create its incremental PLT.
          """)

        true ->
          info("Finding suitable PLTs")
          force_check? = Keyword.get(opts, :force_check, false)
          plt_check_fun().(force_check?)
      end

      default = Dialyxir.Project.default_ignore_warnings()
      ignore_warnings = Dialyxir.Project.dialyzer_ignore_warnings()

      cond do
        !ignore_warnings && File.exists?(default) ->
          info("""
          No :ignore_warnings opt specified in mix.exs. Using default: #{default}.
          """)

        ignore_warnings && File.exists?(ignore_warnings) &&
            match?(%{size: size} when size == 0, File.stat!(ignore_warnings)) ->
          info("""
          :ignore_warnings opt specified in mix.exs: #{ignore_warnings}, but file is empty.
          """)

        ignore_warnings && File.exists?(ignore_warnings) ->
          info("""
          ignore_warnings: #{ignore_warnings}
          """)

        ignore_warnings ->
          info("""
          :ignore_warnings opt specified in mix.exs: #{ignore_warnings}, but file does not exist.
          """)

        true ->
          info("""
          No :ignore_warnings opt specified in mix.exs and default does not exist.
          """)
      end

      warn_old_options(opts)

      unless opts[:plt] do
        run_dialyzer(opts, dargs, final_apps, final_warning_apps)
      end
    else
      info("No mix project found - checking core PLTs...")
      Project.plts_list([], false) |> Plt.check()
    end

    Mix.shell(original_shell)
  end

  def clean(opts, fun \\ &delete_plt/4) do
    check_dialyzer()
    compatibility_notice()
    if opts[:all], do: Project.plts_list([], false) |> Plt.check(fun)

    if Mix.Project.get() do
      {apps, _hash} = dependency_hash()
      info("Deleting PLTs")
      Project.plts_list(apps, true, true) |> Plt.check(fun)
      info("About to delete PLT hash file: #{plt_hash_file()}")
      File.rm(plt_hash_file())
    end
  end

  def delete_plt(plt, _, _, _) do
    info("About to delete PLT file: #{plt}")
    File.rm(plt)
  end

  defp no_check?(opts) do
    case {in_child?(), no_plt?()} do
      {true, true} ->
        info("In an Umbrella child and no PLT found - building that first.")
        build_parent_plt()
        true

      {true, false} ->
        info("In an Umbrella child, not checking PLT...")
        true

      _ ->
        opts[:no_check]
    end
  end

  defp plt_check_fun do
    Application.get_env(:dialyxir, :plt_check_fun, &check_plt/1)
  end

  defp check_plt(force_check?) do
    info("Checking PLT...")
    {apps, hash} = dependency_hash()

    if not force_check? and check_hash?(hash) do
      info("PLT is up to date!")
    else
      Project.plts_list(apps) |> Plt.check()
      File.write(plt_hash_file(), hash)
    end
  end

  defp run_dialyzer(opts, dargs, apps, warning_apps) do
    incremental? = Keyword.get(opts, :incremental, false)

    plt_file = Project.plt_file(incremental?)

    args = [
      {:check_plt, opts[:force_check] || false},
      {:init_plt, String.to_charlist(plt_file)},
      {:warnings, dialyzer_warnings(dargs)},
      {:format, Keyword.get_values(opts, :format)},
      {:raw, opts[:raw]},
      {:list_unused_filters, opts[:list_unused_filters]},
      {:ignore_exit_status, opts[:ignore_exit_status]},
      {:quiet_with_result, opts[:quiet_with_result]},
      {:incremental, incremental?}
    ]

    args =
      args
      |> maybe_put_apps(apps)
      |> maybe_put_warning_apps(warning_apps)
      |> maybe_put_files(apps, warning_apps)

    {status, exit_status, [time | result]} = Dialyzer.dialyze(args)
    info(time)

    quiet_with_result? = opts[:quiet_with_result]

    report =
      cond do
        status == :ok && quiet_with_result? ->
          fn text ->
            Mix.shell(Mix.Shell.IO)
            info(text)
            Mix.shell(Mix.Shell.Quiet)
          end

        status == :ok ->
          &info/1

        true ->
          &error/1
      end

    Enum.each(result, report)

    unless exit_status == 0 || opts[:ignore_exit_status] do
      error("Halting VM with exit status #{exit_status}")
      System.halt(exit_status)
    end
  end

  defp maybe_put_apps(opts, []), do: opts
  defp maybe_put_apps(opts, apps), do: Keyword.put(opts, :apps, apps)

  defp maybe_put_warning_apps(opts, []), do: opts
  defp maybe_put_warning_apps(opts, apps), do: Keyword.put(opts, :warning_apps, apps)

  defp maybe_put_files(args, apps, _warning_apps) do
    cond do
      apps != [] ->
        # Application-based mode: when apps are provided, do NOT pass files.
        # --apps and --files are mutually exclusive modes in Dialyzer.
        # Dialyzer will resolve app names to their BEAM files internally.
        args

      true ->
        # File-based mode: no apps provided, pass files directly
        files = Project.dialyzer_files()
        [{:files, files} | args]
    end
  end

  defp parse_apps_list(opts, key) do
    opts
    |> Keyword.get_values(key)
    |> Enum.flat_map(&String.split(&1, ","))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.to_atom/1)
  end

  defp normalize_apps(apps) when is_list(apps) do
    Enum.map(apps, &normalize_app/1)
  end

  defp normalize_apps(_), do: []

  defp normalize_app(app) when is_atom(app), do: app
  defp normalize_app(app) when is_binary(app), do: String.to_atom(app)

  defp normalize_app(app) when is_list(app) do
    # Handle charlists (like ~c"app_name")
    app |> List.to_string() |> String.to_atom()
  end

  defp filter_missing_apps(apps, context) when is_list(apps) do
    {valid_apps, missing_apps} =
      Enum.split_with(apps, &app_exists?/1)

    if missing_apps != [] do
      warning("""
      The following applications in #{context} were not found and will be skipped:
      #{inspect(missing_apps)}

      This may cause Dialyzer to miss type information from these applications.
      """)
    end

    valid_apps
  end

  defp app_exists?(app) do
    # Check if app is already loaded (most reliable check)
    loaded_app = Application.get_application(app)

    if loaded_app != nil do
      true
    else
      # For OTP apps, check if lib_dir exists
      # For local project apps, we let them through and let Dialyzer validate
      case :code.lib_dir(app) do
        {:error, :bad_name} ->
          # Not an OTP app - might be local project app, let Dialyzer handle it
          true

        path when is_list(path) ->
          # OTP app exists
          path_str = List.to_string(path)
          File.exists?(path_str)
      end
    end
  end

  defp dialyzer_warnings(dargs) do
    raw_opts = Project.dialyzer_flags() ++ Enum.map(dargs, &elem(&1, 0))
    transform(raw_opts) ++ (@default_warnings -- Project.dialyzer_removed_defaults())
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
    case Project.no_umbrella?() do
      true -> false
      false -> String.contains?(Mix.Project.config()[:lockfile], "..")
    end
  end

  defp no_plt? do
    not File.exists?(Project.deps_plt())
  end

  defp build_parent_plt() do
    parent = Mix.Project.config()[:lockfile] |> Path.expand() |> Path.dirname()
    opts = [into: IO.stream(:stdio, :line), stderr_to_stdout: true, cd: parent]
    # It would seem more natural to use Mix.in_project here to start in our parent project.
    # However part of the app.tree resolution includes loading all sub apps, and we will
    # hit an exception when we try to do that for *this* child, which is already loaded.
    {out, rc} = System.cmd("mix", ["dialyzer", "--plt"], opts)

    unless rc == 0 do
      info("Error building parent PLT, process returned code: #{rc}\n#{out}")
    end
  end

  defp resolve_incremental(nil), do: resolve_incremental(Project.dialyzer_incremental())
  defp resolve_incremental(false), do: false

  defp resolve_incremental(true) do
    otp_version = :erlang.system_info(:otp_release) |> List.to_string() |> String.to_integer()

    if otp_version < 26 do
      error("""
      INCREMENTAL MODE NOT SUPPORTED
      ------------------------
      Incremental mode requires OTP 26 or later. Current OTP version: #{otp_version}

      To use incremental mode, upgrade to OTP 26 or later.

      To run Dialyzer without incremental mode:
        - Remove 'incremental: true' from your mix.exs dialyzer config, OR
        - Don't use the --incremental flag
      """)

      :erlang.halt(3)
    end

    true
  end

  if Version.match?(System.version(), ">= 1.15.0") do
    defp check_dialyzer do
      Mix.ensure_application!(:dialyzer)
    end
  else
    defp check_dialyzer do
      if not Code.ensure_loaded?(:dialyzer) do
        error("""
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
        """)

        :erlang.halt(3)
      end
    end
  end

  defp warn_old_options(opts) do
    for {opt, _} <- opts, @old_options[opt] do
      error("#{opt} is no longer a valid CLI argument.")
    end

    nil
  end

  defp compatibility_notice do
    old_plt = "#{user_home!()}/.dialyxir_core_*.plt"

    if File.exists?(old_plt) &&
         (!File.exists?(Project.erlang_plt()) || !File.exists?(Project.elixir_plt())) do
      info("""
      COMPATIBILITY NOTICE
      ------------------------
      Previous usage of a pre-0.4 version of Dialyxir detected. Please be aware that the 0.4 release
      makes a number of changes to previous defaults. Among other things, the PLT task is automatically
      run when dialyzer is run, PLT paths have changed,
      transitive dependencies are included by default in the PLT, and no additional warning flags
      beyond the dialyzer defaults are included. All these properties can be changed in configuration.
      (see `mix help dialyzer`).

      If you no longer use the older Dialyxir in any projects and do not want to see this notice each time you upgrade your Erlang/Elixir distribution, you can delete your old pre-0.4 PLT files. (`rm ~/.dialyxir_core_*.plt`)
      """)
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
    apps = Project.cons_apps()
    apps |> inspect() |> info()
    hash = :crypto.hash(:sha, lock_file() <> :erlang.term_to_binary(apps))
    {apps, hash}
  end

  defp lock_file() do
    lockfile = Mix.Project.config()[:lockfile]
    read_res = File.read(lockfile)

    case read_res do
      {:ok, data} ->
        data

      {:error, :enoent} ->
        # If there is no lock file, an empty bitstring will do to indicate there is none there
        <<>>

      {:error, reason} ->
        raise File.Error,
          reason: reason,
          action: "read file",
          path: lockfile
    end
  end
end
