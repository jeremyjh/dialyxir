defmodule Mix.Tasks.Dialyzer.Plt do
  use Mix.Task
  import System, only: [cmd: 1, user_home!: 0, version: 0]

  @shortdoc "Builds PLT with default erlang applications included."

  @moduledoc """
  Builds PLT with default Erlang applications: 
    erts kernel stdlib crypto public_key 
  You can define a plt_apps in your Mix project config to override defaults
  
  
  e.g.
    def project do
      [ app: :my_app,
        version: "0.0.1",
        deps: deps,
        dialyzer: plt_apps: ["erts","kernel", "stdlib", "crypto", "public_key", "mnesia"]
      ]
    end
  Also includes all libraries included in the current Elixir.
  """
  def run(_) do
    if need_build? do
      build_plt
      if need_add?, do: add_plt
    else
      if need_add?, do: add_plt,
      else: IO.puts "Nothing to do."
    end
  end

  def core_apps do
    (Mix.project[:dialyzer][:plt_apps] 
    || ["erts","kernel", "stdlib", "crypto", "public_key"])
    |> Enum.join(" ")
  end

  def plt_file, do: "#{user_home!}/.dialyxir_core_#{:erlang.system_info(:otp_release)}_#{version}.plt"

  defp need_build? do
    not File.exists?(plt_file)
  end

  defp build_plt do
    IO.puts "Starting PLT Core Build ... this will take awhile"
    cmds = "dialyzer --output_plt #{plt_file} --build_plt --apps #{core_apps} -r #{ex_lib_path}"
    IO.puts cmds
    IO.puts cmd(cmds)
  end

  defp need_add? do
    missing_apps != []
  end

  defp add_plt do
    apps = missing_apps
    IO.puts "Some apps are missing and will be added:"
    IO.inspect apps
    IO.puts "Adding Erlang/OTP Apps to existing PLT ... this will take a little time"
    cmds = "dialyzer --add_to_plt --plt #{plt_file} --apps #{apps}"
    IO.puts cmds
    IO.puts cmd(cmds)
  end

  defp missing_apps do
    missing_apps = core_apps
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
