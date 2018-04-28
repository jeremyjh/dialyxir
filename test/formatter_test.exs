defmodule Dialyxir.Test.FormatterTest do

  use ExUnit.Case

  test "simple atoms are parsed appropriately" do
    input = "'ok'"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = ":ok"
    assert pretty_printed == expected_output
  end

  test "true is parsed appropriately" do
    input = "true"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "true"
    assert pretty_printed == expected_output
  end

  test "false is parsed appropriately" do
    input = "false"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "false"
    assert pretty_printed == expected_output
  end

  test "integers are parsed appropriately" do
    input = "1"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "1"
    assert pretty_printed == expected_output
  end

  test "module names are parsed appropriately" do
    input = "Elixir.Plug.Conn"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "Plug.Conn"
    assert pretty_printed == expected_output
  end

  test "maps are parsed appropriately" do
    input = ~S"#{'halted':='true'}"

    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "%{:halted => true}"
    assert pretty_printed == expected_output
  end

  test "structs are parsed appropriately" do
    input = ~S"#{'halted':='true', '__struct__':='Elixir.Plug.Conn'}"

    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "%Plug.Conn{:halted => true}"
    assert pretty_printed == expected_output
  end

  test "structs with any arrows are parsed appropriately" do
    input = ~S"#{'halted':='true', '__struct__':='Elixir.Plug.Conn', _ => _}"

    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "%Plug.Conn{:halted => true, _ => _}"
    assert pretty_printed == expected_output
  end

  test "one arg tuples are parsed appropriately" do
    input = "{'ok'}"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "{:ok}"
    assert pretty_printed == expected_output
  end

  test "ranges are parsed appropriately" do
    input = "1..5"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "1..5"
    assert pretty_printed == expected_output
  end

  test "zero arg functions are parsed appropriately" do
    input = "fun(() -> 1)"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "(() -> 1)"
    assert pretty_printed == expected_output
  end
end
