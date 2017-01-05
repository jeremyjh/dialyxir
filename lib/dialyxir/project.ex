defmodule Dialyxir.Project do
  @moduledoc false

  def plts_list(deps, include_project \\ true) do
    elixir_apps = [:elixir]
    erlang_apps = [:erts, :kernel, :stdlib, :crypto]
    core_plts = [ {elixir_plt(), elixir_apps}, {erlang_plt(), erlang_apps}]
    if include_project do
      [{plt_file(), deps ++ elixir_apps ++ erlang_apps} | core_plts]
    else
      core_plts
    end
  end

  def plt_file() do
    plt_path(dialyzer_config()[:plt_file])
    || deps_plt()
  end
  defp plt_path(file) when is_binary(file), do: Path.expand(file)
  defp plt_path({:no_warn, file}) when is_binary(file), do: Path.expand(file)
  defp plt_path(_),  do: false

  def check_config do
    if is_binary(dialyzer_config()[:plt_file]) do
      IO.puts """
      Notice: :plt_file is deprecated as Dialyxir now uses project-private PLT files by default.
      If you want to use this setting without seeing this warning, provide it in a pair
      with the :no_warn key e.g. `dialyzer: plt_file: {:no_warn, "~/mypltfile"}`
      """
    end
  end

  def cons_apps do
    Mix.Tasks.Deps.Loadpaths.run([]) #compile & load all deps paths
    Mix.Project.compile([]) # compile & load current project paths
    (plt_apps() || (plt_add_apps() ++ include_deps()))
      |> Enum.sort |> Enum.uniq
  end

  def dialyzer_paths do
    dialyzer_config()[:paths] || default_paths()
  end

  def dialyzer_ignore_warnings do
    dialyzer_config()[:ignore_warnings]
  end

  def filter_warnings(output, pattern) do
    lines = output
            |> String.trim_trailing("\n")
            |> String.split("\n")
    patterns = pattern
               |> String.trim_trailing("\n")
               |> String.split("\n")
    cp = :binary.compile_pattern(patterns)

    Enum.filter(lines, &(not String.contains?(&1, cp)))
  end

  def elixir_plt() do
    global_plt("erlang-#{otp_vsn()}_elixir-#{System.version()}")
  end

  def erlang_plt(), do: global_plt("erlang-" <> otp_vsn())

  defp otp_vsn() do
    major = :erlang.system_info(:otp_release)
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

  def deps_plt do
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
    Path.join(Mix.Project.build_path(), "dialyxir_" <> name <> ".plt")
  end

  defp default_paths() do
    reduce_umbrella_children([], fn(paths) ->
      [Mix.Project.compile_path | paths]
    end)
  end

  defp plt_apps, do: dialyzer_config()[:plt_apps] |> load_apps()
  defp plt_add_apps, do: dialyzer_config()[:plt_add_apps] || [] |> load_apps()
  defp load_apps(apps) do
    if apps do
      Enum.map(apps, &Application.load/1)
      apps
    end
  end

  defp include_deps do
    method = dialyzer_config()[:plt_add_deps]
    reduce_umbrella_children([],fn(deps) ->
      deps ++ case method do
        false         -> []
        true          -> deps_project()  ++ deps_app(false) #compatibility
        :project      -> deps_project() ++ deps_app(false)
        :apps_direct  -> deps_app(false)
        :transitive   -> deps_transitive() ++ deps_app(true)
        _app_tree     -> deps_app(true)
      end
    end)
  end

  defp deps_project do
    Mix.Project.config[:deps]
      |> Enum.filter(&env_dep(&1))
      |> Enum.map(&elem(&1,0))
  end

  defp deps_transitive do
    Mix.Project.deps_paths
      |> Map.keys
  end

  @spec deps_app(boolean()) :: [atom]
  defp deps_app(recursive) do
    app = Mix.Project.config[:app]
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

  defp dialyzer_config(), do: Mix.Project.config[:dialyzer]
end
