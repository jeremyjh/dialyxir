defmodule Dialyxir.Warnings.UnmatchedReturn do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :unmatched_return
  def warning(), do: :unmatched_return

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([type]) do
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)

    """
    Expression produces a value of type:

    #{pretty_type}

    but this value is unmatched.
    """
  end
end
