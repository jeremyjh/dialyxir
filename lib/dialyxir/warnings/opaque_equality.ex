defmodule Dialyxir.Warnings.OpaqueEquality do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :opaque_eq
  def warning(), do: :opaque_eq

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([type, _op, opaque_type]) do
    "Attempt to test for equality between a term of type #{type} " <>
      "and a term of opaque type #{opaque_type}."
  end
end
