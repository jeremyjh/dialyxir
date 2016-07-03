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
  import System, only: [cmd: 3, user_home!: 0, version: 0]
  import Dialyxir.Helpers

  def run(_) do
    if need_add?, do: add_plt
    check_plt
  end

  def plt_file do
    Mix.Project.config[:dialyzer][:plt_file]
      || "#{user_home!}/.dialyxir_core_#{:erlang.system_info(:otp_release)}_#{version}.plt"
  end

  defp check_plt do
    action = if need_build? do
      puts "Starting PLT Core Build ... this will take awhile"
      ["--build_plt", "--output_plt"]
    else
      puts "Checking PLT for updated apps."
      ["--check_plt", "--plt"]
    end
    args = List.flatten [action, "#{plt_file}", include_pa, "--apps", include_apps, "-r", ex_lib_path]
    puts "dialyzer " <> Enum.join(args, " ")
    {ret, _} = cmd("dialyzer", args, [])
    puts ret
  end

  defp add_plt do
    apps = missing_apps
    puts "Some apps are missing and will be added:"
    puts Enum.join(apps, " ")
    puts "Adding apps to existing PLT ... this will take a little time"
    args = List.flatten ["--add_to_plt", "--plt", "#{plt_file}", include_pa, "--apps", apps]
    puts "dialyzer " <> Enum.join(args, " ")
    {ret, _} = cmd("dialyzer", args, [])
    puts ret
  end

  defp include_apps, do: Enum.map(cons_apps, &to_binary_if_atom(&1))

  defp to_binary_if_atom(b) when is_binary(b), do: b
  defp to_binary_if_atom(a) when is_atom(a), do: Atom.to_string(a)

  defp cons_apps, do: ((plt_apps || (default_apps ++ plt_add_apps)) ++ include_deps)

  #paths for dependencies that are specified in plt_apps, plt_add_apps, or plt_add_deps
  defp include_pa do
    case Enum.filter(deps_transitive, &(&1 in cons_apps)) do
      [] -> []
      apps ->
        Enum.map(apps, fn(a) ->
          ["-pa", "_build/" <> "#{Mix.env}/lib/" <> Atom.to_string(a) <> "/ebin"] end)
    end
  end

  defp plt_apps, do: Mix.Project.config[:dialyzer][:plt_apps]
  defp plt_add_apps, do: Mix.Project.config[:dialyzer][:plt_add_apps] || []
  defp default_apps, do: [:erts, :kernel, :stdlib, :crypto, :public_key]

  defp include_deps do
    case Mix.Project.config[:dialyzer][:plt_add_deps] do
      true -> deps_project #compatibility
      :project -> deps_project
      :transitive -> deps_transitive
      _ -> []
    end
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

  defp env_dep(dep) do
    only_envs = dep_only(dep)
    only_envs == nil || Mix.env in List.wrap(only_envs)
  end
  defp dep_only({_, opts}) when is_list(opts), do: opts[:only]
  defp dep_only({_, _, opts}) when is_list(opts), do: opts[:only]
  defp dep_only(_), do: nil

  defp need_build? do
    not File.exists?(plt_file)
  end

  defp need_add? do
    if !need_build? do
      IO.puts "Checking PLT for missing apps."
      missing_apps != []
    else
      false
    end
  end


  defp missing_apps do
    missing_apps = include_apps
      |> Enum.filter(fn(app) ->
          not core_plt_contains?(app,plt_file)
         end)
    missing_apps
  end

  defp core_plt_contains?(app, plt_file) do
    app = to_char_list(app)
    plt_file = to_char_list(plt_file)
    :dialyzer.plt_info(plt_file)
    |> elem(1) |> Keyword.get(:files)
    |> Enum.find(fn(s) ->
                   :string.str(s, app) > 0
                 end)
    |> is_list
  end

  defp ex_lib_path do
    code_dir = Path.join(:code.lib_dir(:elixir), "..")
    ~w[eex elixir ex_unit iex logger mix]
    |> Enum.map(&Path.join([ code_dir, &1, "ebin" ]))
  end
end
