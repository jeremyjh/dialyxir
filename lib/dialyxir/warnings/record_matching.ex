defmodule Dialyxir.Warnings.RecordMatching do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :record_matching
  def warning(), do: :record_matching

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([string, name]) do
    "The #{string} violates the declared type for ##{name}{}."
  end
end
