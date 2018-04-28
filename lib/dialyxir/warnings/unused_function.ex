defmodule Dialyxir.Warnings.UnusedFunction do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :unused_fun
  def warning(), do: :unused_fun

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([]) do
    "Function will never be called."
  end

  def format_long([function, arity]) do
    "Function #{function}/#{arity} will never be called."
  end
end
