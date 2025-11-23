defmodule Mix.Tasks.DialyzerTest do
  use ExUnit.Case

  import ExUnit.CaptureIO, only: [capture_io: 1]

  defmodule DialyzerStub do
    def run(_args), do: []
  end

  defmodule DialyzerArgsCapture do
    def run(args) do
      parent = Application.get_env(:dialyxir, :test_parent)
      if parent, do: send(parent, {:dialyzer_args, args})
      []
    end
  end

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

  test "incremental configuration is properly recognized" do
    in_project(:incremental, fn ->
      assert Dialyxir.Project.dialyzer_incremental() == true
    end)
  end

  test "incremental configuration defaults to false when not specified" do
    in_project(:local_plt, fn ->
      assert Dialyxir.Project.dialyzer_incremental() == false
    end)
  end

  test "CLI flag --incremental is parsed correctly" do
    # Test that the CLI flag is properly parsed
    {opts, _, _} = OptionParser.parse(["--incremental"], strict: [incremental: :boolean])
    assert opts[:incremental] == true

    {opts, _, _} = OptionParser.parse([], strict: [incremental: :boolean])
    assert opts[:incremental] == nil
  end

  test "PLT check is skipped when incremental mode is enabled" do
    in_project(:incremental, fn ->
      parent = self()

      Application.put_env(:dialyxir, :dialyzer_module, DialyzerStub)

      Application.put_env(:dialyxir, :plt_check_fun, fn force_check? ->
        send(parent, {:plt_check_called, force_check?})
        :ok
      end)

      on_exit(fn ->
        Application.delete_env(:dialyxir, :dialyzer_module)
        Application.delete_env(:dialyxir, :plt_check_fun)
      end)

      output =
        capture_io(fn ->
          Mix.Tasks.Dialyzer.run(["--incremental", "--no-compile", "--ignore-exit-status"])
        end)

      assert output =~ "Incremental mode enabled; skipping PLT check step"
      refute_receive {:plt_check_called, _}
    end)
  end

  describe "apps and warning_apps" do
    test "CLI flag --apps is parsed correctly" do
      {opts, _, _} =
        OptionParser.parse(
          ["--apps", "my_app,other_app"],
          strict: [apps: :keep]
        )

      assert Keyword.get_values(opts, :apps) == ["my_app,other_app"]
    end

    test "CLI flag --apps with multiple invocations is parsed correctly" do
      {opts, _, _} =
        OptionParser.parse(
          ["--apps", "my_app", "--apps", "other_app"],
          strict: [apps: :keep]
        )

      assert Keyword.get_values(opts, :apps) == ["my_app", "other_app"]
    end

    test "CLI flag --warning-apps is parsed correctly" do
      {opts, _, _} =
        OptionParser.parse(
          ["--warning-apps", "my_app"],
          strict: [warning_apps: :keep]
        )

      assert Keyword.get_values(opts, :warning_apps) == ["my_app"]
    end

    test "apps configuration is properly recognized" do
      in_project(:apps_config, fn ->
        assert Dialyxir.Project.dialyzer_apps() == [:apps_config, :kernel]
      end)
    end

    test "warning_apps configuration is properly recognized" do
      in_project(:apps_warning_apps_config, fn ->
        assert Dialyxir.Project.dialyzer_warning_apps() == [:apps_warning_apps_config]
      end)
    end

    test "apps configuration defaults to empty list when not configured" do
      in_project(:local_plt, fn ->
        assert Dialyxir.Project.dialyzer_apps() == []
      end)
    end

    test "warning_apps configuration defaults to empty list when not configured" do
      in_project(:local_plt, fn ->
        assert Dialyxir.Project.dialyzer_warning_apps() == []
      end)
    end

    test "error when --apps used without --incremental" do
      in_project(:local_plt, fn ->
        output =
          capture_io(fn ->
            try do
              Mix.Tasks.Dialyzer.run([
                "--apps",
                "my_app",
                "--no-compile",
                "--ignore-exit-status"
              ])
            catch
              :exit, _ -> :ok
            end
          end)

        assert output =~ "--apps and --warning-apps can only be used with --incremental"
      end)
    end

    test "error when --warning-apps used without --incremental" do
      in_project(:local_plt, fn ->
        output =
          capture_io(fn ->
            try do
              Mix.Tasks.Dialyzer.run([
                "--warning-apps",
                "my_app",
                "--no-compile",
                "--ignore-exit-status"
              ])
            catch
              :exit, _ -> :ok
            end
          end)

        assert output =~ "--apps and --warning-apps can only be used with --incremental"
      end)
    end

    test "apps option is passed to Dialyzer when provided via CLI" do
      in_project(:incremental, fn ->
        parent = self()

        Application.put_env(:dialyxir, :dialyzer_module, DialyzerArgsCapture)
        Application.put_env(:dialyxir, :test_parent, parent)

        on_exit(fn ->
          Application.delete_env(:dialyxir, :dialyzer_module)
          Application.delete_env(:dialyxir, :test_parent)
        end)

        capture_io(fn ->
          Mix.Tasks.Dialyzer.run([
            "--incremental",
            "--apps",
            "my_app",
            "--no-compile",
            "--ignore-exit-status"
          ])
        end)

        assert_receive {:dialyzer_args, args}
        assert Keyword.has_key?(args, :apps)
        assert Keyword.get(args, :apps) == [['my_app']]
        refute Keyword.has_key?(args, :files)
      end)
    end

    test "apps option is passed to Dialyzer when provided via config" do
      in_project(:apps_config, fn ->
        parent = self()

        Application.put_env(:dialyxir, :dialyzer_module, DialyzerArgsCapture)
        Application.put_env(:dialyxir, :test_parent, parent)

        on_exit(fn ->
          Application.delete_env(:dialyxir, :dialyzer_module)
          Application.delete_env(:dialyxir, :test_parent)
        end)

        capture_io(fn ->
          Mix.Tasks.Dialyzer.run([
            "--incremental",
            "--no-compile",
            "--ignore-exit-status"
          ])
        end)

        assert_receive {:dialyzer_args, args}
        assert Keyword.has_key?(args, :apps)
        apps = Keyword.get(args, :apps)
        assert length(apps) == 2
        assert ['apps_config'] in apps
        assert ['kernel'] in apps
        refute Keyword.has_key?(args, :files)
      end)
    end

    test "warning_apps option is passed to Dialyzer when provided" do
      in_project(:apps_warning_apps_config, fn ->
        parent = self()

        Application.put_env(:dialyxir, :dialyzer_module, DialyzerArgsCapture)
        Application.put_env(:dialyxir, :test_parent, parent)

        on_exit(fn ->
          Application.delete_env(:dialyxir, :dialyzer_module)
          Application.delete_env(:dialyxir, :test_parent)
        end)

        capture_io(fn ->
          Mix.Tasks.Dialyzer.run([
            "--incremental",
            "--no-compile",
            "--ignore-exit-status"
          ])
        end)

        assert_receive {:dialyzer_args, args}
        assert Keyword.has_key?(args, :warning_apps)
        warning_apps = Keyword.get(args, :warning_apps)
        assert [['apps_warning_apps_config']] == warning_apps
      end)
    end

    test "both apps and warning_apps can be used together" do
      in_project(:apps_warning_apps_config, fn ->
        parent = self()

        Application.put_env(:dialyxir, :dialyzer_module, DialyzerArgsCapture)
        Application.put_env(:dialyxir, :test_parent, parent)

        on_exit(fn ->
          Application.delete_env(:dialyxir, :dialyzer_module)
          Application.delete_env(:dialyxir, :test_parent)
        end)

        capture_io(fn ->
          Mix.Tasks.Dialyzer.run([
            "--incremental",
            "--no-compile",
            "--ignore-exit-status"
          ])
        end)

        assert_receive {:dialyzer_args, args}
        assert Keyword.has_key?(args, :apps)
        assert Keyword.has_key?(args, :warning_apps)
        refute Keyword.has_key?(args, :files)
      end)
    end

    test "CLI apps values override config values" do
      in_project(:apps_config, fn ->
        parent = self()

        Application.put_env(:dialyxir, :dialyzer_module, DialyzerArgsCapture)
        Application.put_env(:dialyxir, :test_parent, parent)

        on_exit(fn ->
          Application.delete_env(:dialyxir, :dialyzer_module)
          Application.delete_env(:dialyxir, :test_parent)
        end)

        capture_io(fn ->
          Mix.Tasks.Dialyzer.run([
            "--incremental",
            "--apps",
            "cli_app",
            "--no-compile",
            "--ignore-exit-status"
          ])
        end)

        assert_receive {:dialyzer_args, args}
        assert Keyword.get(args, :apps) == [['cli_app']]
      end)
    end

    test "CLI warning_apps values override config values" do
      in_project(:apps_warning_apps_config, fn ->
        parent = self()

        Application.put_env(:dialyxir, :dialyzer_module, DialyzerArgsCapture)
        Application.put_env(:dialyxir, :test_parent, parent)

        on_exit(fn ->
          Application.delete_env(:dialyxir, :dialyzer_module)
          Application.delete_env(:dialyxir, :test_parent)
        end)

        capture_io(fn ->
          Mix.Tasks.Dialyzer.run([
            "--incremental",
            "--warning-apps",
            "cli_warning_app",
            "--no-compile",
            "--ignore-exit-status"
          ])
        end)

        assert_receive {:dialyzer_args, args}
        assert Keyword.get(args, :warning_apps) == [['cli_warning_app']]
      end)
    end

    test "files option is included when apps is not provided" do
      in_project(:incremental, fn ->
        parent = self()

        Application.put_env(:dialyxir, :dialyzer_module, DialyzerArgsCapture)
        Application.put_env(:dialyxir, :test_parent, parent)

        on_exit(fn ->
          Application.delete_env(:dialyxir, :dialyzer_module)
          Application.delete_env(:dialyxir, :test_parent)
        end)

        capture_io(fn ->
          Mix.Tasks.Dialyzer.run([
            "--incremental",
            "--no-compile",
            "--ignore-exit-status"
          ])
        end)

        assert_receive {:dialyzer_args, args}
        assert Keyword.has_key?(args, :files)
        refute Keyword.has_key?(args, :apps)
      end)
    end

    test "apps with comma-separated values are parsed correctly" do
      in_project(:incremental, fn ->
        parent = self()

        Application.put_env(:dialyxir, :dialyzer_module, DialyzerArgsCapture)
        Application.put_env(:dialyxir, :test_parent, parent)

        on_exit(fn ->
          Application.delete_env(:dialyxir, :dialyzer_module)
          Application.delete_env(:dialyxir, :test_parent)
        end)

        capture_io(fn ->
          Mix.Tasks.Dialyzer.run([
            "--incremental",
            "--apps",
            "my_app,other_app,third_app",
            "--no-compile",
            "--ignore-exit-status"
          ])
        end)

        assert_receive {:dialyzer_args, args}
        apps = Keyword.get(args, :apps)
        assert length(apps) == 3
        assert ['my_app'] in apps
        assert ['other_app'] in apps
        assert ['third_app'] in apps
      end)
    end
  end
end
