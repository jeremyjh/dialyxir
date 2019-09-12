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
end
