defmodule Dialyxir.Warnings.OpaqueTypeTest do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :opaque_type_test
  def warning(), do: :opaque_type_test

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([function, opaque]) do
    "The type test #{function}(#{opaque}) breaks the opaqueness of the term #{opaque}."
  end
end
