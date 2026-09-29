defmodule Dialyxir.Test.WarningTest do
  use ExUnit.Case

  # Don't test output in here, just that it can succeed.

  test "pattern match warning succeeds on valid input" do
    arguments = [~c"pattern {'ok', Vuser@1}", ~c"{'error',<<_:64,_:_*8>>}"]
    assert(Dialyxir.Warnings.PatternMatch.format_long(arguments))
  end

  test "exact compare warning with == can never evaluate to true" do
    arguments = [~c"'dev'", ~c"==", ~c"'test'"]
    result = Dialyxir.Warnings.ExactCompare.format_long(arguments)
    assert result =~ "can never evaluate to 'true'"
  end

  test "exact compare warning with =:= can never evaluate to true" do
    arguments = [~c"'dev'", ~c"=:=", ~c"'test'"]
    result = Dialyxir.Warnings.ExactCompare.format_long(arguments)
    assert result =~ "can never evaluate to 'true'"
  end

  test "exact compare warning with /= can never evaluate to false" do
    arguments = [~c"'ok'", ~c"/=", ~c"'ok'"]
    result = Dialyxir.Warnings.ExactCompare.format_long(arguments)
    assert result =~ "can never evaluate to 'false'"
  end

  test "exact compare warning with =/= can never evaluate to false" do
    arguments = [~c"'ok'", ~c"=/=", ~c"'ok'"]
    result = Dialyxir.Warnings.ExactCompare.format_long(arguments)
    assert result =~ "can never evaluate to 'false'"
  end

  test "exact compare warning is registered" do
    warnings = Dialyxir.Warnings.warnings()
    assert Map.has_key?(warnings, :exact_compare)
    assert warnings[:exact_compare] == Dialyxir.Warnings.ExactCompare
  end

  # The full formatter pipeline calls :dialyzer.format_warning/2, which only
  # recognises OTP 28 warning types on OTP 28+. Test the Dialyxir formatter
  # directly so the test suite passes on all supported OTP versions.
  test "exact compare warning formats through the Dialyxir formatter" do
    warning =
      {:warn_matching, {~c"lib/example.ex", {10, 5}},
       {:exact_compare, [~c"'dev'", ~c"==", ~c"'test'"]}}

    formatted = Dialyxir.Formatter.Dialyxir.format(warning)

    assert formatted =~ "exact_compare"
    assert formatted =~ "can never evaluate to 'true'"
  end

  # --- call_with_opaque ---

  test "call with opaque warning accepts integer argument positions (OTP 27 and earlier)" do
    arguments = [~c"binary", ~c"split", ~c"(_, _)", [2], [:erl_types.t_atom()]]
    result = Dialyxir.Warnings.CallWithOpaque.format_long(arguments)
    assert result =~ "an opaque term in 2nd argument"
    assert result =~ "a structured term of type atom() is expected"
  end

  test "call with opaque warning accepts position triples (OTP 28 and later)" do
    conflicts = [{2, :erl_types.t_atom(), ~c"atom()"}]
    arguments = [~c"binary", ~c"split", ~c"(_, _)", conflicts, [:erl_types.t_atom()]]
    result = Dialyxir.Warnings.CallWithOpaque.format_long(arguments)
    assert result =~ "an opaque term in 2nd argument"
    assert result =~ "a structured term of type atom() is expected"
  end

  test "call with opaque warning lists several triple positions" do
    conflicts = [{1, :erl_types.t_atom(), ~c"atom()"}, {3, :erl_types.t_atom(), ~c"atom()"}]
    expected = [:erl_types.t_atom(), :erl_types.t_binary()]
    arguments = [~c"binary", ~c"split", ~c"(_, _, _)", conflicts, expected]
    result = Dialyxir.Warnings.CallWithOpaque.format_long(arguments)
    assert result =~ "opaque terms in 1st and 3rd arguments"
    assert String.ends_with?(result, "terms of different types are expected in these positions.")
  end

  # --- opaque_compare (OTP 28, replaces opaque_eq + opaque_neq) ---

  test "opaque compare warning with == reports equality" do
    arguments = [~c"integer()", ~c"==", ~c"atom()"]
    result = Dialyxir.Warnings.OpaqueCompare.format_long(arguments)
    assert result =~ "equality"
    assert result =~ "opaque type"
  end

  test "opaque compare warning with /= reports inequality" do
    arguments = [~c"integer()", ~c"/=", ~c"atom()"]
    result = Dialyxir.Warnings.OpaqueCompare.format_long(arguments)
    assert result =~ "inequality"
    assert result =~ "opaque type"
  end

  test "opaque compare warning is registered" do
    warnings = Dialyxir.Warnings.warnings()
    assert Map.has_key?(warnings, :opaque_compare)
    assert warnings[:opaque_compare] == Dialyxir.Warnings.OpaqueCompare
  end

  test "opaque compare warning formats through the Dialyxir formatter" do
    warning =
      {:warn_opaque, {~c"lib/example.ex", {10, 5}},
       {:opaque_compare, [~c"integer()", ~c"==", ~c"atom()"]}}

    formatted = Dialyxir.Formatter.Dialyxir.format(warning)

    assert formatted =~ "opaque_compare"
    assert formatted =~ "equality"
  end

  # --- opaque_union (new in OTP 28) ---

  test "opaque union warning with opaque body" do
    arguments = [true, ~c"atom()"]
    result = Dialyxir.Warnings.OpaqueUnion.format_long(arguments)
    assert result =~ "opaque type"
    assert result =~ "broken by the other clauses"
  end

  test "opaque union warning with non-opaque body" do
    arguments = [false, ~c"integer()"]
    result = Dialyxir.Warnings.OpaqueUnion.format_long(arguments)
    assert result =~ "violates the opacity"
  end

  test "opaque union warning is registered" do
    warnings = Dialyxir.Warnings.warnings()
    assert Map.has_key?(warnings, :opaque_union)
    assert warnings[:opaque_union] == Dialyxir.Warnings.OpaqueUnion
  end

  test "opaque union warning formats through the Dialyxir formatter" do
    warning =
      {:warn_opaque, {~c"lib/example.ex", {10, 5}}, {:opaque_union, [true, ~c"atom()"]}}

    formatted = Dialyxir.Formatter.Dialyxir.format(warning)

    assert formatted =~ "opaque_union"
    assert formatted =~ "opaque type"
  end
end
