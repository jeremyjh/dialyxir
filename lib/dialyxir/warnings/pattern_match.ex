defmodule Dialyxir.Warnings.PatternMatch do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :pattern_match
  def warning(), do: :pattern_match

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([[pattern, type]]) do
    pretty_pattern = Dialyxir.PrettyPrint.pretty_print_pattern(pattern)
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)
    "The #{pretty_pattern} can never match the type #{pretty_type}."
  end
end
