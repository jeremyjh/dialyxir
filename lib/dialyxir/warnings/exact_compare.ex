defmodule Dialyxir.Warnings.ExactCompare do
  @moduledoc """
  The test can never evaluate to the expected value.

  This is a comparison where the result is determined at compile time:
  either the compared terms can never be equal (for `==` / `=:=`), or
  they can never be different (for `/=` / `=/=`).

  ## Example

      defmodule Example do
        def ok() do
          :ok == :error
        end
      end
  """

  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :exact_compare
  def warning(), do: :exact_compare

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short(args), do: format_long(args)

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([type1, op, type2]) do
    pretty_type1 = Erlex.pretty_print_type(type1)
    pretty_type2 = Erlex.pretty_print_type(type2)

    op_string = to_string(op)
    result = if op_string in ["=:=", "=="], do: "true", else: "false"

    "The test #{pretty_type1} #{op} #{pretty_type2} can never evaluate to '#{result}'."
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    @moduledoc
  end
end
