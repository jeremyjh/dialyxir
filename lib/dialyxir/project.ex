defmodule Dialyxir.Project do
  alias Dialyxir.Plt
  @moduledoc false

  def plt_file() do
    plt_path(Mix.Project.config[:dialyzer][:plt_file])
    || Plt.deps_plt()
  end

  defp plt_path(file) when is_binary(file), do: Path.expand(file)
  defp plt_path({:no_warn, file}) when is_binary(file), do: Path.expand(file)
  defp plt_path(_),  do: false

  def check_config do
    if is_binary(Mix.Project.config[:dialyzer][:plt_file]) do
      IO.puts """
      Notice: :plt_path is deprecated as Dialyxir now uses project-private PLT files by default.
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
    Mix.Project.config[:dialyzer][:paths] || default_paths()
  end

  defp default_paths() do
    reduce_umbrella_children([], fn(paths) ->
      [Mix.Project.compile_path | paths]
    end)
  end

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
        false         -> []
        true          -> deps_project()  ++ deps_app(false) #compatibility
        :project      -> deps_project() ++ deps_app(false)
        :apps_direct  -> deps_app(false)
        :transitive   -> deps_transitive() ++ deps_app(true)
        _apps_tree    -> deps_app(true)
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
end
