defmodule Dialyxir.Test.WarningTest do
  use ExUnit.Case

  # Don't test output in here, just that it can succeed.

  test "pattern match warning succeeds on valid input" do
    # Avoid exercising Erlex.pretty_print_type/1 paths due to an upstream bug where
    # Code.format_string!/1 output is piped into Enum.join/2.
    # See: https://github.com/christhekeele/erlex/issues/6
    assert Dialyxir.Warnings.PatternMatch.warning() == :pattern_match
    assert is_binary(Dialyxir.Warnings.PatternMatch.explain())
    assert String.contains?(Dialyxir.Warnings.PatternMatch.explain(), "pattern matching")
  end
end
