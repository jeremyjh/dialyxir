defmodule Dialyxir.Warnings.PatternMatchCovered do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :pattern_match_cov
  def warning(), do: :pattern_match_cov

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([pattern, type]) do
    pretty_pattern = Dialyxir.PrettyPrint.pretty_print_pattern(pattern)
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)

    "The #{pretty_pattern} can never match since previous clauses " <>
      "completely covered the type #{pretty_type}."
  end
end
