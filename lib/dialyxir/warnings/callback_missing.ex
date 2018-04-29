defmodule Dialyxir.Warnings.CallbackMissing do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :callback_missing
  def warning(), do: :callback_missing

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([function, arity, behaviour]) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)

    "Undefined callback function #{function}/#{arity} (behaviour #{pretty_behaviour})."
  end
end
