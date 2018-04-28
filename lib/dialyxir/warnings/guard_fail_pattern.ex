defmodule Dialyxir.Warnings.GuardFailPattern do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :guard_fail_pat
  def warning(), do: :guard_fail_pat

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([pattern, type]) do
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)
    pretty_pattern = Dialyxir.PrettyPrint.pretty_print_pattern(pattern)

    "Clause guard cannot succeed. The pattern #{pretty_pattern} " <>
      "was matched against the type #{pretty_type}."
  end
end
