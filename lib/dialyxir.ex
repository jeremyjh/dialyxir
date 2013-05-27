defmodule Mix.Tasks.Dialyze do
  use Mix.Task

  @shortdoc "Runs dialyzer with default or project-defined flags."

  @moduledoc """
  Runs dialyzer with default flags: 
    -Wunmatched_returns -Werror_handling -Wrace_conditions -Wunderspecs

  You can define a dialyze_flags key in your Mix project config to override defaults.
  You can also include a dialyze_paths key to override default path (only ebin)
  
  e.g.
    def project do
      [ app: :mix_dialyze,
        version: "0.0.1",
        deps: deps,
        dialyze_flags: ["-Werror_handling", "-Wrace_conditions"],
        dialyze_paths: ["ebin", "deps/foo/ebin"]
      ]
    end
  """
  def run(_) do
    IO.puts "Starting Dialyzer"
    cmds = "dialyzer --quiet --no_check_plt --plt .depsolver.plt #{dialyze_flags} #{dialyze_paths}"
    IO.puts cmds
    IO.puts :os.cmd(binary_to_list(cmds))
  end

  defp dialyze_flags do
    (Mix.project[:dialyze_flags]
    || ["-Wunmatched_returns","-Werror_handling","-Wrace_conditions","-Wunderspecs"])
    |> Enum.join(" ")
  end

  defp dialyze_paths do
    (Mix.project[:dialyze_paths] || ["ebin"])
    |> Enum.join(" ")
  end

  defmodule Plt do
    @shortdoc "Builds PLT with default erlang applications included."

    @moduledoc """
    Builds PLT with default Erlang applications: 
      erts kernel stdlib crypto public_key 
    You can define a plt_apps in your Mix project config to override defaults

    
    
    Also includes all libraries included in the current Elixir.
    """
    def run(_) do
      IO.puts "Starting PLT Build ... this will take awhile"
      cmds = "dialyzer -DDIALYZER --output_plt .depsolver.plt --build_plt --apps #{plt_apps}"# -r #{ex_lib_path}"
      IO.puts cmds
      IO.puts :os.cmd(binary_to_list(cmds))
    end

    def plt_apps do
      (Mix.project[:plt_apps] 
      || ["erts","kernel", "stdlib", "crypto", "public_key"])
      |> Enum.join(" ")
    end

    defp ex_lib_path, do: "#{list_to_binary(:code.lib_dir(:elixir))}/.."
  end

  defmodule Add do
  end

  defmodule Check do
    @shortdoc "Check if PLT contains all required apps and is up to date."

    @moduledoc """
    Check if PLT is up to date.
    """
    def run(_) do
      if not missing_apps?(Plt.plt_apps, './.depsolver.plt'), do: check_plt
    end

    defp missing_apps?(required_apps, plt_file) do
      missing_apps = required_apps 
        |> String.split(" ")
        |> Enum.filter(fn(app) ->
            not core_plt_contains?(app,plt_file)
           end)
      if missing_apps == [] do
        IO.puts "All apps are present"
        false
      else 
        IO.puts "Some apps are missing, add them with dialyze.plt.add: "
        IO.inspect missing_apps
        true
      end
    end

    defp check_plt do
      IO.puts "Starting PLT check ..."
      cmds = "dialyzer --check_plt --plt .depsolver.plt"
      IO.puts cmds
      IO.puts :os.cmd(binary_to_list(cmds))
    end

    defp core_plt_contains?(app, plt_file) do
      unless is_list(app), do:  app = binary_to_list(app)
      unless is_list(plt_file), do:  plt_file = binary_to_list(plt_file)
      :dialyzer.plt_info(plt_file) 
      |> elem(1) |> Keyword.get(:files) 
      |> Enum.find(fn(s) -> 
           :string.str(s, app) > 0
         end)
      |> is_list
    end
  end

end

