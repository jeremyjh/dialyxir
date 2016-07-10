defmodule Mix.Tasks.Dialyzer.Plt do
  @shortdoc "Builds PLT with default erlang applications included."

  @moduledoc """
  Builds PLT with default core Erlang applications:
    erts kernel stdlib crypto public_key
  Also includes all modules in the Elixir standard library.


  ## Configuration

  All configuration is included under a dialyzer key in the project entry, e.g.

      def project do
        [ app: :my_app,
          version: "0.0.1",
          deps: deps,
          dialyzer: plt_add_apps: [:mnesia]
                  , plt_file: ".private.plt"
        ]
      end

  * `dialyzer: :plt_add_apps` - OTP or project dependency applications to include *in addition* to the core applications.


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
  import Dialyxir.Plt

  def run(_) do
    IO.puts "Checking PLT..."
    {apps, hash} = dependency_hash
    if check_hash?(hash) do
      IO.puts "PLT is up to date!"
    else
      Mix.Tasks.Deps.Check.run([]) #compile & load all deps paths
      Mix.Project.compile([]) # compile & load current project paths
      plts_list(apps) |> check()
      File.write(plt_hash_file, hash)
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
	  deps_plt() <> ".hash"
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
    case Mix.Project.config[:dialyzer][:plt_add_deps] do
      false    -> []
      true     -> deps_project() #compatibility
      :project -> deps_project()
      _        -> deps_transitive()
    end
  end

  defp deps_project do
    deps = Mix.Project.config[:deps]
              |> Enum.filter(&env_dep(&1))
              |> Enum.map(&elem(&1,0))
    Enum.uniq(deps_app(false) ++ deps)
  end
  defp deps_transitive do
    deps = (Mix.Project.deps_paths
              |> Map.keys)
    Enum.uniq(deps_app(true) ++ deps)
  end

  @spec deps_app(boolean()) :: [atom]
  defp deps_app(recursive) do
    app = Keyword.fetch!(Mix.Project.config(), :app)
    deps_app(app,recursive) |> Enum.uniq
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
end
