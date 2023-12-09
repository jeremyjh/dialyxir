defmodule Dialyxir.Warnings.RecordMatch do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :record_match
  def warning(), do: :record_match

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  defdelegate format_short(args), to: Dialyxir.Warnings.RecordMatching

  @impl Dialyxir.Warning
  defdelegate format_long(args), to: Dialyxir.Warnings.RecordMatching

  @impl Dialyxir.Warning
  defdelegate explain(), to: Dialyxir.Warnings.RecordMatching
end
