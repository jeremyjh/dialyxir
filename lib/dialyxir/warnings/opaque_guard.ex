defmodule Dialyxir.Warnings.OpaqeGuard do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :opaque_guard
  def warning(), do: :opaque_guard

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([guard, args]) do
    "Guard test #{guard}#{args} breaks the opaqueness of its argument."
  end
end
