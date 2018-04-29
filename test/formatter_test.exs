defmodule Dialyxir.Test.FormatterTest do

  use ExUnit.Case

  test "simple atoms are pretty printed appropriately" do
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

  test "integers are pretty printed appropriately" do
    input = "1"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "1"
    assert pretty_printed == expected_output
  end

  test "module names are pretty printed appropriately" do
    input = "Elixir.Plug.Conn"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "Plug.Conn"
    assert pretty_printed == expected_output
  end

  test "module types are pretty printed appropriately" do
    input = "'Elixir.Plug.Conn':t()"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "Plug.Conn.t()"
    assert pretty_printed == expected_output
  end

  test "atom types are pretty printed appropriately" do
    input = "atom()"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "atom()"
    assert pretty_printed == expected_output
  end

  test "or'd simple types are pretty printed appropriately" do
    input = "binary() | integer()"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "binary() | integer()"
    assert pretty_printed == expected_output
  end

  test "or'd mixed types are pretty printed appropriately" do
    input = "'Elixir.Keyword':t() | map()"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "Keyword.t() | map()"
    assert pretty_printed == expected_output
  end

  test "or'd mixed types function signatures are pretty printed appropriately" do
    input = "('Elixir.Plug.Conn':t(),binary() | atom(),'Elixir.Keyword':t() | map()) -> 'Elixir.Plug.Conn':t()"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "(Plug.Conn.t(), binary() | atom(), Keyword.t() | map()) :: Plug.Conn.t()"
    assert pretty_printed == expected_output
  end

  test "named values are pretty printed appropriately" do
    input = "data::'Elixir.MyApp.Data':t()"

    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "data :: MyApp.Data.t()"
    assert pretty_printed == expected_output
  end

  test "maps are pretty printed appropriately" do
    input = ~S"#{'halted':='true'}"

    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "%{:halted => true}"
    assert pretty_printed == expected_output
  end

  test "structs are pretty printed appropriately" do
    input = ~S"#{'halted':='true', '__struct__':='Elixir.Plug.Conn'}"

    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "%Plug.Conn{:halted => true}"
    assert pretty_printed == expected_output
  end

  test "structs with any arrows are pretty printed appropriately" do
    input = ~S"#{'halted':='true', '__struct__':='Elixir.Plug.Conn', _ => _}"

    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "%Plug.Conn{:halted => true, _ => _}"
    assert pretty_printed == expected_output
  end

  test "one arg tuples are pretty printed appropriately" do
    input = "{'ok'}"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "{:ok}"
    assert pretty_printed == expected_output
  end

  test "three arg tuples are parsed appropriately" do
    input = "{'ok', 'error', 'ok'}"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "{:ok, :error, :ok}"
    assert pretty_printed == expected_output
  end

  test "ranges are pretty printed appropriately" do
    input = "1..5"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "1..5"
    assert pretty_printed == expected_output
  end

  test "zero arg functions in contract are pretty printed appropriately" do
    input = "() -> atom()"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "() :: atom()"
    assert pretty_printed == expected_output
  end

  test "binary is parsed appropriately" do
    input = "<<_:64,_:_*8>>"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "String.t()"
    assert pretty_printed == expected_output
  end

  test "zero arg functions are pretty printed appropriately" do
    input = "fun(() -> 1)"
    pretty_printed = Dialyxir.PrettyPrint.pretty_print(input)

    expected_output = "(() -> 1)"
    assert pretty_printed == expected_output
  end
end
