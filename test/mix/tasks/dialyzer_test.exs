defmodule Mix.Tasks.DialyzerTest do
  use ExUnit.Case

  import ExUnit.CaptureIO, only: [capture_io: 1]

  defp in_project(app, f) when is_atom(app) do
    Mix.Project.in_project(app, "test/fixtures/#{Atom.to_string(app)}", fn _ -> f.() end)
  end

  defp no_delete_plt(plt, _, _, _), do: IO.puts("About to delete PLT file: #{plt}")

  test "Delete PLT file name" do
    in_project(:local_plt, fn ->
      fun = fn -> Mix.Tasks.Dialyzer.clean([], &no_delete_plt/4) end

      assert Regex.match?(
               ~r/About to delete PLT file: .*\/test\/fixtures\/local_plt\/local.plt/,
               capture_io(fun)
             )
    end)
  end

  test "Core PLTs are not deleted without --all flag" do
    in_project(:local_plt, fn ->
      fun = fn -> Mix.Tasks.Dialyzer.clean([], &no_delete_plt/4) end

      assert not Regex.match?(
               ~r/About to delete PLT file: .*dialyxir_erlang/,
               capture_io(fun)
             )
    end)
  end

  test "Core PLTs are deleted with --all flag" do
    in_project(:local_plt, fn ->
      fun = fn -> Mix.Tasks.Dialyzer.clean([{:all, true}], &no_delete_plt/4) end

      assert Regex.match?(
               ~r/About to delete PLT file: .*dialyxir_erlang/,
               capture_io(fun)
             )
    end)
  end

  @tag :output_tests
  test "Informational output is suppressed with --quiet" do
    args = ["dialyzer", "--quiet"]
    env = [{"MIX_ENV", "prod"}]
    {result, 0} = System.cmd("mix", args, env: env)
    assert result == ""
  end
end
