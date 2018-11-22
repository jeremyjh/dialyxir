defmodule Dialyxir.DialyzerTest do
  use ExUnit.Case
  alias Dialyxir.Dialyzer

  describe "dialyze/3" do
    import Dialyzer, only: [dialyze: 3]

    test "formatting with no warnings" do
      defmodule StubSuccess do
        def run(_, _), do: {:ok, {"time", [], ""}}
      end

      {expected_result_code, expected_exit_code, expected_messages} =
        dialyze(nil, StubSuccess, nil)

      assert expected_result_code == :ok
      assert expected_exit_code == 0
      assert expected_messages == ["time", "", "\e[32mdone (passed successfully)\e[0m"]
    end

    test "formatting with warnings" do
      defmodule StubWarn do
        def run(_, _), do: {:ok, {"time", ["warning 1", "warning 2"], ""}}
      end

      {expected_result_code, expected_exit_code, expected_messages} = dialyze(nil, StubWarn, nil)

      assert expected_result_code == :warn
      assert expected_exit_code == 2

      assert expected_messages == [
               "time",
               "\e[31mwarning 1\e[0m",
               "\e[31mwarning 2\e[0m",
               "",
               "\e[33mdone (warnings were emitted)\e[0m"
             ]
    end

    test "formatting with errors" do
      defmodule StubError do
        def run(_, _), do: {:error, "dialyzer failed"}
      end

      {expected_result_code, expected_exit_code, expected_messages} = dialyze(nil, StubError, nil)

      assert expected_result_code == :error
      assert expected_exit_code == 1
      assert expected_messages == ["\e[31mdialyzer failed\e[0m"]
    end
  end
end
