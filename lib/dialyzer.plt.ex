defmodule Mix.Tasks.Dialyzer.Plt do
  use Mix.Task
  import System, only: [cmd: 1, user_home!: 0, version: 0]

  @shortdoc "Builds PLT with default erlang applications included."

  @moduledoc """
  Builds PLT with default core Erlang applications:
    erts kernel stdlib crypto public_key


    def project do
      [ app: :my_app,
        version: "0.0.1",
        deps: deps,
        dialyzer: plt_add_apps: [:mnesia, :erlzmq]
      ]
    end
  Also includes all libraries included in the current Elixir.


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

  * `dialyzer: :plt_add_apps` - applications to include *in addition* to the core named above e.g.

      [:mnesia]

  * `dialyzer: :plt_apps` - a list of applications to include that will replace the default,
  include all the apps you need e.g.

      [:erts, :kernel, :stdlib, :mnesia]

  * `dialyzer: :plt_file` - specify the plt file name to create and use - default is to use
  a shared PLT in the user's home directory specific to the version of Erlang/Elixir

     ".local.plt"

  * `dialyzer: :plt_deps` - Bool - include the project's dependencies in the PLT. Defaults true.

  """
  def run(_) do
    if need_build? do
      build_plt
      if need_add?, do: add_plt
    else
      if need_add?, do: add_plt,
      else: Mix.shell.info "Nothing to do."
    end
  end

  def plt_file do
    Mix.project[:dialyzer][:plt_file]
      || "#{user_home!}/.dialyxir_core_#{:erlang.system_info(:otp_release)}_#{version}.plt"
  end

  defp include_apps do
    ((plt_apps || (default_apps ++ plt_add_apps)) ++ deps_apps)
      |> Enum.map(atom_to_binary(&1))
      |> Enum.join(" ")
  end

  defp plt_apps, do: Mix.project[:dialyzer][:plt_apps]
  defp plt_add_apps, do: Mix.project[:dialyzer][:plt_add_apps] || []
  defp default_apps, do: [:erts, :kernel, :stdlib, :crypto, :public_key]

  defp deps_apps do
    if Mix.project[:dialyzer][:plt_deps] == false, do: [],
    else: Mix.project[:deps] |> Enum.map(elem(&1,0))
  end

  defp need_build? do
    not File.exists?(plt_file)
  end

  defp build_plt do
    Mix.shell.info "Starting PLT Core Build ... this will take awhile"
    cmds = "dialyzer --output_plt #{plt_file} --build_plt --apps #{include_apps} -r #{ex_lib_path}"
    Mix.shell.info cmds
    Mix.shell.info cmd(cmds)
  end

  defp need_add? do
    missing_apps != []
  end

  defp add_plt do
    apps = missing_apps
    Mix.shell.info "Some apps are missing and will be added:"
    Mix.shell.info Kernel.inspect(apps)
    Mix.shell.info "Adding Erlang/OTP Apps to existing PLT ... this will take a little time"
    cmds = "dialyzer --add_to_plt --plt #{plt_file} --apps #{apps}"
    Mix.shell.info cmds
    Mix.shell.info cmd(cmds)
  end

  defp missing_apps do
    missing_apps = include_apps
      |> String.split(" ")
      |> Enum.filter(fn(app) ->
          not core_plt_contains?(app,plt_file)
         end)
    missing_apps
  end

  defp core_plt_contains?(app, plt_file) do
    app = binary_to_list(app)
    plt_file = binary_to_list(plt_file)
    :dialyzer.plt_info(plt_file)
    |> elem(1) |> Keyword.get(:files)
    |> Enum.find(fn(s) ->
         :string.str(s, app) > 0
       end)
    |> is_list
  end

  defp ex_lib_path, do: "#{list_to_binary(:code.lib_dir(:elixir))}/.."
end
