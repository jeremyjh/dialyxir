defmodule Dialyxir.Warnings.OpaqueMatch do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :opaque_match
  def warning(), do: :opaque_match

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([pattern, opaque_type, opaque_term]) do
    term =
      if opaque_type == opaque_term do
        "the term"
      else
        opaque_term
      end

    pretty_pattern = Dialyxir.PrettyPrint.pretty_print_pattern(pattern)

    "The attempt to match a term of type #{opaque_term} against the #{pretty_pattern} breaks the opaqueness of #{
      term
    }."
  end
end
