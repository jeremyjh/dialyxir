defmodule Dialyxir.Warnings.UnknownBehaviour do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :unknown_behaviour
  def warning(), do: :unknown_behaviour

  @impl Dialyxir.Warning
  @spec format_long(String.t()) :: String.t()
  def format_long(behaviour) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(behaviour)

    "Unknown behaviour: #{pretty_module}."
  end
end
