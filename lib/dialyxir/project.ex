defmodule Dialyxir.Project do
  @moduledoc false
  import Dialyxir.Output

  alias Dialyxir.FilterMap
  alias Dialyxir.Formatter.Short
  alias Dialyxir.Formatter.Utils

  # Maximum depth in the dependency tree to traverse before giving up.
  @max_dep_traversal_depth 100

  def plts_list(deps, include_project \\ true, exclude_core \\ false) do
    elixir_apps = [:elixir]
    erlang_apps = [:erts, :kernel, :stdlib, :crypto]

    core_plts =
      if exclude_core do
        []
      else
        [{elixir_plt(), elixir_apps}, {erlang_plt(), erlang_apps}]
      end

    if include_project do
      [{plt_file(), deps ++ elixir_apps ++ erlang_apps} | core_plts]
    else
      core_plts
    end
  end

  def plt_file() do
    plt_path(dialyzer_config()[:plt_file]) || deps_plt()
  end

  defp plt_path(file) when is_binary(file), do: Path.expand(file)
  defp plt_path({:no_warn, file}) when is_binary(file), do: Path.expand(file)
  defp plt_path(_), do: false

  def check_config do
    if is_binary(dialyzer_config()[:plt_file]) do
      warning("""
      Notice: :plt_file is deprecated as Dialyxir now uses project-private PLT files by default.
      If you want to use this setting without seeing this warning, provide it in a pair
      with the :no_warn key e.g. `dialyzer: plt_file: {:no_warn, "~/mypltfile"}`
      """)
    end
  end

  def cons_apps do
    # compile & load all deps paths
    _ = Mix.Tasks.Deps.Loadpaths.run([])
    # compile & load current project paths
    Mix.Task.run("compile")
    apps = plt_apps() || plt_add_apps() ++ include_deps()

    apps
    |> Enum.sort()
    |> Enum.uniq()
    |> Kernel.--(plt_ignore_apps())
  end

  def dialyzer_files do
    beam_files =
      dialyzer_paths()
      |> Enum.flat_map(&beam_files_with_paths/1)
      |> Map.new()

    consolidated_files =
      Mix.Project.consolidation_path()
      |> beam_files_with_paths()
      |> Enum.filter(fn {file_name, _path} -> beam_files |> Map.has_key?(file_name) end)
      |> Map.new()

    beam_files
    |> Map.merge(consolidated_files)
    |> Enum.map(fn {_file, path} -> path end)
    |> reject_exclude_files()
    |> Enum.map(&to_charlist(&1))
  end

  defp reject_exclude_files(files) do
    file_exclusions = dialyzer_config()[:exclude_files] || []

    Enum.reject(files, fn file ->
      :lists.any(
        fn reject_file_pattern ->
          re = <<reject_file_pattern::binary, "$">>
          result = :re.run(file, re)

          case result do
            {:match, _captured} -> true
            :nomatch -> false
          end
        end,
        file_exclusions
      )
    end)
  end

  defp dialyzer_paths do
    paths = dialyzer_config()[:paths] || default_paths()
    excluded_paths = dialyzer_config()[:excluded_paths] || []
    Enum.map(paths -- excluded_paths, &String.to_charlist/1)
  end

  defp beam_files_with_paths(path) do
    path |> Path.join("*.beam") |> Path.wildcard() |> Enum.map(&{Path.basename(&1), &1})
  end

  def dialyzer_removed_defaults do
    dialyzer_config()[:remove_defaults] || []
  end

  def dialyzer_flags do
    Mix.Project.config()[:dialyzer][:flags] || []
  end

  def no_umbrella? do
    case dialyzer_config()[:no_umbrella] do
      true -> true
      _other -> false
    end
  end

  defp skip?({file, warning, line}, {file, warning, line, _, _}), do: true

  defp skip?({file, warning_description}, {file, _, _, _, warning_description})
       when is_binary(warning_description),
       do: true

  defp skip?({file, warning}, {file, warning, _, _, _}) when is_atom(warning), do: true
  defp skip?({file}, {file, _, _, _, _}), do: true

  defp skip?({short_description, warning, line}, {_, warning, line, short_description, _}),
    do: true

  defp skip?({short_description, warning}, {_, warning, _, short_description, _}), do: true
  defp skip?({short_description}, {_, _, _, short_description, _}), do: true

  defp skip?(%Regex{} = pattern, {_, _, _, short_description, _}) do
    Regex.match?(pattern, short_description)
  end

  defp skip?(_, _), do: false

  def filter_warning?(
        {_, {file, line}, {warning_type, args}} = warning,
        filter_map = %FilterMap{}
      ) do
    short_description = Short.format(warning)
    warning_description = Utils.warning(warning_type).format_short(args)

    {matching_filters, _non_matching_filters} =
      filter_map
      |> FilterMap.filters()
      |> Enum.split_with(
        &skip?(&1, {to_string(file), warning_type, line, short_description, warning_description})
      )

    {not Enum.empty?(matching_filters), matching_filters}
  end

  def filter_map(args) do
    cond do
      legacy_ignore_warnings?() ->
        %FilterMap{}

      dialyzer_ignore_warnings() == nil && !File.exists?(default_ignore_warnings()) ->
        %FilterMap{}

      true ->
        ignore_file = dialyzer_ignore_warnings() || default_ignore_warnings()

        FilterMap.from_file(ignore_file, list_unused_filters?(args), ignore_exit_status?(args))
    end
  end

  def filter_legacy_warnings(output) do
    ignore_file = dialyzer_ignore_warnings()

    if legacy_ignore_warnings?() do
      pattern = File.read!(ignore_file)
      filter_legacy_warnings(output, pattern)
    else
      output
    end
  end

  def filter_legacy_warnings(output, nil), do: output
  def filter_legacy_warnings(output, ""), do: output

  def filter_legacy_warnings(output, pattern) do
    lines = Enum.map(output, &String.trim_trailing/1)

    patterns =
      pattern
      |> String.trim_trailing("\n")
      |> String.split("\n")
      |> Enum.reject(&(&1 == ""))

    try do
      Enum.reject(lines, fn line ->
        Enum.any?(patterns, &String.contains?(line, &1))
      end)
    rescue
      _ ->
        output
    end
  end

  @spec legacy_ignore_warnings?() :: boolean
  defp legacy_ignore_warnings?() do
    case dialyzer_ignore_warnings() do
      nil ->
        false

      ignore_file ->
        !String.ends_with?(ignore_file, ".exs")
    end
  end

  def default_ignore_warnings() do
    ".dialyzer_ignore.exs"
  end

  def dialyzer_ignore_warnings() do
    dialyzer_config()[:ignore_warnings]
  end

  def list_unused_filters?(args) do
    case Keyword.fetch(args, :list_unused_filters) do
      {:ok, list_unused_filters} when not is_nil(list_unused_filters) ->
        list_unused_filters

      _else ->
        dialyzer_config()[:list_unused_filters]
    end
  end

  defp ignore_exit_status?(args) do
    args[:ignore_exit_status]
  end

  def elixir_plt() do
    global_plt("erlang-#{otp_vsn()}_elixir-#{System.version()}")
  end

  def erlang_plt(), do: global_plt("erlang-" <> otp_vsn())

  defp otp_vsn() do
    major = :erlang.system_info(:otp_release) |> List.to_string()
    vsn_file = Path.join([:code.root_dir(), "releases", major, "OTP_VERSION"])

    try do
      {:ok, contents} = File.read(vsn_file)
      String.split(contents, "\n", trim: true)
    else
      [full] ->
        full

      _ ->
        major
    catch
      :error, _ ->
        major
    end
  end

  def deps_plt() do
    name = "erlang-#{otp_vsn()}_elixir-#{System.version()}_deps-#{build_env()}"
    local_plt(name)
  end

  defp build_env() do
    config = Mix.Project.config()

    case Keyword.fetch!(config, :build_per_environment) do
      true -> Atom.to_string(Mix.env())
      false -> "shared"
    end
  end

  defp global_plt(name) do
    Path.join(core_path(), "dialyxir_" <> name <> ".plt")
  end

  defp core_path(), do: dialyzer_config()[:plt_core_path] || Mix.Utils.mix_home()

  defp local_plt(name) do
    Path.join(local_path(), "dialyxir_" <> name <> ".plt")
  end

  defp local_path(), do: dialyzer_config()[:plt_local_path] || Mix.Project.build_path()

  defp default_paths() do
    reduce_umbrella_children([], fn paths ->
      [Mix.Project.compile_path() | paths]
    end)
  end

  defp plt_apps, do: dialyzer_config()[:plt_apps] |> load_apps()
  defp plt_add_apps, do: dialyzer_config()[:plt_add_apps] || [] |> load_apps()
  defp plt_ignore_apps, do: dialyzer_config()[:plt_ignore_apps] || []

  defp load_apps(nil), do: nil

  defp load_apps(apps) do
    Enum.each(apps, &Application.load/1)
    apps
  end

  defp include_deps do
    method = dialyzer_config()[:plt_add_deps]

    initial_acc = {
      _loaded_apps = [],
      _unloaded_apps = [],
      _initial_load_statuses = %{}
    }

    {loaded_apps, _unloaded_apps, _final_load_statuses} =
      reduce_umbrella_children(initial_acc, fn acc ->
        case method do
          false ->
            acc

          # compatibility
          true ->
            warning(
              "Dialyxir has deprecated plt_add_deps: true in favor of apps_direct, which includes only runtime dependencies."
            )

            acc
            |> load_project_deps()
            |> load_external_deps(recursive: false)

          :project ->
            warning(
              "Dialyxir has deprecated plt_add_deps: :project in favor of apps_direct, which includes only runtime dependencies."
            )

            acc
            |> load_project_deps()
            |> load_external_deps(recursive: false)

          :apps_direct ->
            load_external_deps(acc, recursive: false)

          :transitive ->
            warning(
              "Dialyxir has deprecated plt_add_deps: :transitive in favor of app_tree, which includes only runtime dependencies."
            )

            acc
            |> load_transitive_deps()
            |> load_external_deps(recursive: true)

          _app_tree ->
            load_external_deps(acc, recursive: true)
        end
      end)

    loaded_apps
  end

  defp load_project_deps({loaded_apps, unloaded_apps, load_statuses}) do
    apps =
      Mix.Project.config()[:deps]
      |> Enum.filter(&env_dep(&1))
      |> Enum.map(&elem(&1, 0))

    app_load_statuses = Map.new(apps, &{elem(&1, 0), :loaded})

    update_load_statuses({loaded_apps, unloaded_apps -- apps, load_statuses}, app_load_statuses)
  end

  defp load_transitive_deps({loaded_apps, unloaded_apps, load_statuses}) do
    apps = Mix.Project.deps_paths() |> Map.values()
    app_load_statuses = Map.new(apps, &{elem(&1, 0), :loaded})

    update_load_statuses({loaded_apps, unloaded_apps -- apps, load_statuses}, app_load_statuses)
  end

  defp load_external_deps({loaded_apps, _unloaded_apps, load_statuses}, opts) do
    # Non-recursive traversal of 2 tries to load the app immediate deps.
    traversal_depth =
      case Keyword.fetch!(opts, :recursive) do
        true -> @max_dep_traversal_depth
        false -> 2
      end

    app = Mix.Project.config()[:app]

    # Even if already loaded, we'll need to traverse it again to get its deps.
    load_statuses_w_app = Map.put(load_statuses, app, {:unloaded, :required})
    traverse_deps_for_apps({loaded_apps -- [app], [app], load_statuses_w_app}, traversal_depth)
  end

  defp traverse_deps_for_apps({loaded_apps, [] = unloaded_deps, load_statuses}, _rem_depth),
    do: {loaded_apps, unloaded_deps, load_statuses}

  defp traverse_deps_for_apps({loaded_apps, unloaded_deps, load_statuses}, 0 = _rem_depth),
    do: {loaded_apps, unloaded_deps, load_statuses}

  defp traverse_deps_for_apps({loaded_apps, apps_to_load, load_statuses}, rem_depth) do
    initial_acc = {loaded_apps, [], load_statuses}

    {updated_loaded_apps, updated_unloaded_apps, updated_load_statuses} =
      Enum.reduce(apps_to_load, initial_acc, fn app, acc ->
        required? = Map.fetch!(load_statuses, app) == {:unloaded, :required}
        {app_load_status, app_dep_statuses} = load_app(app, required?)

        acc
        |> update_load_statuses(%{app => app_load_status})
        |> update_load_statuses(app_dep_statuses)
      end)

    traverse_deps_for_apps(
      {updated_loaded_apps, updated_unloaded_apps, updated_load_statuses},
      rem_depth - 1
    )
  end

  defp load_app(app, required?) do
    case do_load_app(app) do
      :ok ->
        {dependencies, optional_deps} = app_dep_specs(app)

        dep_statuses =
          Map.new(dependencies, fn dep ->
            case dep in optional_deps do
              true -> {dep, {:unloaded, :optional}}
              false -> {dep, {:unloaded, :required}}
            end
          end)

        {:loaded, dep_statuses}

      {:error, err} ->
        if required? do
          error("Error loading #{app}, dependency list may be incomplete.\n #{inspect(err)}")
        end

        {{:error, err}, %{}}
    end
  end

  @spec do_load_app(atom()) :: :ok | {:error, term()}
  defp do_load_app(app) do
    case Application.load(app) do
      :ok ->
        :ok

      {:error, {:already_loaded, _}} ->
        :ok

      {:error, err} ->
        {:error, err}
    end
  end

  if System.version() |> Version.parse!() |> (&(&1.major >= 1 and &1.minor >= 15)).() do
    defp app_dep_specs(app) do
      # Values returned by :optional_applications are also in :applications.
      dependencies = Application.spec(app, :applications) || []
      optional_deps = Application.spec(app, :optional_applications) || []

      {dependencies, optional_deps}
    end
  else
    defp app_dep_specs(app) do
      {Application.spec(app, :applications) || [], []}
    end
  end

  defp update_load_statuses({loaded_apps, unloaded_apps, load_statuses}, new_statuses) do
    initial_acc = {loaded_apps, unloaded_apps, load_statuses}

    Enum.reduce(new_statuses, initial_acc, fn {app, new_status}, acc ->
      {current_loaded_apps, current_unloaded_apps, statuses} = acc
      existing_status = Map.get(statuses, app, :unset)

      {new_loaded_apps, new_unloaded_apps, updated_load_statuses} =
        case {existing_status, new_status} do
          {:unset, {:unloaded, _} = new_status} ->
            # Haven't seen this app before.
            {[], [app], Map.put(statuses, app, new_status)}

          {{:unloaded, :optional}, {:unloaded, :required}} ->
            # A previous app had this as optional, but another one requires it.
            {[], [], Map.put(statuses, app, {:unloaded, :required})}

          {{:unloaded, _}, :loaded} ->
            # Final state. Dependency successfully loaded.
            {[app], [], Map.put(statuses, app, :loaded)}

          {{:unloaded, _}, {:error, err}} ->
            # Final state. Dependency failed to load.
            {[], [], Map.put(statuses, app, {:error, err})}

          {_prev_unloaded_or_final, _nwe_unloaded_or_final} ->
            # No status change, or one that doesn't matter like final to final.
            {[], [], statuses}
        end

      {
        new_loaded_apps ++ current_loaded_apps,
        new_unloaded_apps ++ current_unloaded_apps,
        updated_load_statuses
      }
    end)
  end

  defp env_dep(dep) do
    only_envs = dep_only(dep)
    only_envs == nil || Mix.env() in List.wrap(only_envs)
  end

  defp dep_only({_, opts}) when is_list(opts), do: opts[:only]
  defp dep_only({_, _, opts}) when is_list(opts), do: opts[:only]
  defp dep_only(_), do: nil

  @spec reduce_umbrella_children(acc, (acc -> acc)) :: acc when acc: term
  defp reduce_umbrella_children(acc, f) do
    if Mix.Project.umbrella?() do
      children = Mix.Dep.Umbrella.loaded()

      Enum.reduce(children, acc, fn child, acc ->
        Mix.Project.in_project(child.app, child.opts[:path], fn _ ->
          reduce_umbrella_children(acc, f)
        end)
      end)
    else
      f.(acc)
    end
  end

  defp dialyzer_config(), do: Mix.Project.config()[:dialyzer]
end
