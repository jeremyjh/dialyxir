defmodule Dialyxir.Warnings.BinaryConstruction do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :bin_construction
  def warning(), do: :bin_construction

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([culprit, size, segment, type]) do
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)

    "Binary construction will fail since the #{culprit} field #{size} in " <>
      "segment #{segment} has type #{pretty_type}."
  end
end
