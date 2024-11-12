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

  test "Does not crash when running on project without mix.lock" do
    in_project(:no_lockfile, fn ->
      fun = fn -> Mix.Tasks.Dialyzer.clean([], &no_delete_plt/4) end
      capture_io(fun)
      # does not assert anything, we just need to ensure this doesn't crash.
    end)
  end

  @tag :output_tests
  test "Informational output is suppressed with --quiet" do
    args = ["dialyzer", "--quiet"]
    env = [{"MIX_ENV", "prod"}]
    {result, 0} = System.cmd("mix", args, env: env)
    assert result == ""
  end

  @tag :output_tests
  test "Only final result is printed with --quiet-with-result" do
    args = ["dialyzer", "--quiet-with-result"]
    env = [{"MIX_ENV", "prod"}]
    {result, 0} = System.cmd("mix", args, env: env)

    assert result =~
             ~r/Total errors: ., Skipped: ., Unnecessary Skips: .\ndone \(passed successfully\)\n/
  end

  @tag :output_tests
  test "Warning is printed when unknown format is requested" do
    args = ["dialyzer", "--format", "foo"]
    env = [{"MIX_ENV", "prod"}]
    {result, 0} = System.cmd("mix", args, env: env)

    assert result =~
             "Unrecognized formatter foo received. Known formatters are dialyzer, dialyxir, github, ignore_file, ignore_file_strict, raw, and short. Falling back to dialyxir."
  end

  test "task runs when custom ignore file provided and exists" do
    in_project(:ignore, fn ->
      fun = fn -> Mix.Tasks.Dialyzer.run(["--ignore-exit-status"]) end

      assert capture_io(fun) =~ "ignore_warnings: ignore_test.exs"
    end)
  end

  test "task runs when custom ignore file provided and does not exist" do
    in_project(:ignore_custom_missing, fn ->
      fun = fn -> Mix.Tasks.Dialyzer.run(["--ignore-exit-status"]) end

      assert capture_io(fun) =~
               ":ignore_warnings opt specified in mix.exs: ignore_test.exs, but file does not exist"
    end)
  end

  test "task runs when custom ignore file provided and it is empty" do
    in_project(:ignore_custom_empty, fn ->
      fun = fn -> Mix.Tasks.Dialyzer.run(["--ignore-exit-status"]) end

      assert capture_io(fun) =~
               ":ignore_warnings opt specified in mix.exs: ignore_test.exs, but file is empty"
    end)
  end
end
