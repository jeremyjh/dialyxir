defmodule Dialyxir.DialyzerTest do
  use ExUnit.Case
  alias Dialyxir.Dialyzer

  defmodule StubSuccess do
    def run(_, _), do: {:ok, {"time", [], ""}}
  end

  defmodule StubWarn do
    def run(_, _), do: {:ok, {"time", ["warning 1", "warning 2"], ""}}
  end

  defmodule StubError do
    def run(_, _), do: {:error, "dialyzer failed"}
  end

  defmodule ArgsCapture do
    def run(args, _filterer) do
      send(self(), {:dialyzer_args, args})
      {:ok, {"time", [], ""}}
    end
  end

  setup do
    ansi_enabled = IO.ANSI.enabled?()

    on_exit(fn ->
      Application.put_env(:elixir, :ansi_enabled, ansi_enabled)
    end)
  end

  describe "dialyze/3" do
    import Dialyzer, only: [dialyze: 3]

    test "formatting with no warnings, colors enabled" do
      Application.put_env(:elixir, :ansi_enabled, true)

      {expected_result_code, expected_exit_code, expected_messages} =
        dialyze(nil, StubSuccess, nil)

      assert expected_result_code == :ok
      assert expected_exit_code == 0

      assert expected_messages == [
               "time",
               "",
               [[[[] | "\e[32m"], "done (passed successfully)"] | "\e[0m"]
             ]
    end

    test "formatting with no warnings, colors disabled" do
      Application.put_env(:elixir, :ansi_enabled, false)

      {expected_result_code, expected_exit_code, expected_messages} =
        dialyze(nil, StubSuccess, nil)

      assert expected_result_code == :ok
      assert expected_exit_code == 0
      assert expected_messages == ["time", "", [[], "done (passed successfully)"]]
    end

    test "formatting with warnings, colors enabled" do
      Application.put_env(:elixir, :ansi_enabled, true)

      {expected_result_code, expected_exit_code, expected_messages} = dialyze(nil, StubWarn, nil)

      assert expected_result_code == :warn
      assert expected_exit_code == 2

      assert expected_messages == [
               "time",
               [[[[] | "\e[31m"], "warning 1"] | "\e[0m"],
               [[[[] | "\e[31m"], "warning 2"] | "\e[0m"],
               "",
               [[[[] | "\e[33m"], "done (warnings were emitted)"] | "\e[0m"]
             ]
    end

    test "formatting with warnings, colors disabled" do
      Application.put_env(:elixir, :ansi_enabled, false)

      {expected_result_code, expected_exit_code, expected_messages} = dialyze(nil, StubWarn, nil)

      assert expected_result_code == :warn
      assert expected_exit_code == 2

      assert expected_messages == [
               "time",
               [[], "warning 1"],
               [[], "warning 2"],
               "",
               [[], "done (warnings were emitted)"]
             ]
    end

    test "formatting with errors, colors enabled" do
      Application.put_env(:elixir, :ansi_enabled, true)

      {expected_result_code, expected_exit_code, expected_messages} = dialyze(nil, StubError, nil)

      assert expected_result_code == :error
      assert expected_exit_code == 1
      assert expected_messages == [[[[[] | "\e[31m"], "dialyzer failed"] | "\e[0m"]]
    end

    test "formatting with errors, colors disabled" do
      Application.put_env(:elixir, :ansi_enabled, false)

      {expected_result_code, expected_exit_code, expected_messages} = dialyze(nil, StubError, nil)

      assert expected_result_code == :error
      assert expected_exit_code == 1
      assert expected_messages == [[[], "dialyzer failed"]]
    end
  end

  describe "incremental mode args" do
    import Dialyzer, only: [dialyze: 3]

    test "analysis_type :incremental is passed through to runner" do
      args = [
        {:analysis_type, :incremental},
        {:init_plt, ~c"some.plt.incremental"},
        {:output_plt, ~c"some.plt.incremental"},
        {:files, [~c"some_file.beam"]},
        {:warnings, [:unknown]},
        {:format, []},
        {:raw, nil},
        {:list_unused_filters, nil},
        {:ignore_exit_status, nil},
        {:quiet_with_result, nil}
      ]

      dialyze(args, ArgsCapture, nil)

      assert_received {:dialyzer_args, captured_args}
      assert captured_args[:analysis_type] == :incremental
    end

    test "incremental mode uses separate PLT with output_plt" do
      args = [
        {:analysis_type, :incremental},
        {:init_plt, ~c"deps.plt.incremental"},
        {:output_plt, ~c"deps.plt.incremental"},
        {:files, [~c"some_file.beam"]},
        {:warnings, [:unknown]},
        {:format, []},
        {:raw, nil},
        {:list_unused_filters, nil},
        {:ignore_exit_status, nil},
        {:quiet_with_result, nil}
      ]

      dialyze(args, ArgsCapture, nil)

      assert_received {:dialyzer_args, captured_args}
      assert captured_args[:init_plt] == ~c"deps.plt.incremental"
      assert captured_args[:output_plt] == ~c"deps.plt.incremental"
      refute Keyword.has_key?(captured_args, :check_plt)
    end

    test "analysis_type is not present when not specified" do
      args = [
        {:check_plt, false},
        {:init_plt, ~c"some.plt"},
        {:files, [~c"some_file.beam"]},
        {:warnings, [:unknown]},
        {:format, []},
        {:raw, nil},
        {:list_unused_filters, nil},
        {:ignore_exit_status, nil},
        {:quiet_with_result, nil}
      ]

      dialyze(args, ArgsCapture, nil)

      assert_received {:dialyzer_args, captured_args}
      refute Keyword.has_key?(captured_args, :analysis_type)
      refute Keyword.has_key?(captured_args, :output_plt)
    end
  end

  describe "warning scoping" do
    import Dialyzer, only: [dialyze: 3]

    # Warning scope in incremental mode is Dialyzer's job, via `warning_files_rec`
    # (analyze everything, report only the project). This must reach `:dialyzer.run/1`
    # untouched — it is not a dialyxir-internal arg to be split out and dropped.
    test "warning_files_rec is passed through to the runner" do
      args = [
        {:analysis_type, :incremental},
        {:init_plt, ~c"some.plt.incremental"},
        {:output_plt, ~c"some.plt.incremental"},
        {:files, [~c"_build/dev/lib/my_app/ebin/Elixir.MyApp.beam"]},
        {:warning_files_rec, [~c"_build/dev/lib/my_app/ebin"]},
        {:warnings, [:unknown]},
        {:format, []},
        {:raw, nil},
        {:list_unused_filters, nil},
        {:ignore_exit_status, nil},
        {:quiet_with_result, nil}
      ]

      dialyze(args, ArgsCapture, nil)

      assert_received {:dialyzer_args, captured_args}
      assert captured_args[:warning_files_rec] == [~c"_build/dev/lib/my_app/ebin"]
    end
  end
end
