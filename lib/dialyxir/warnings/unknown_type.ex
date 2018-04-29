defmodule Dialyxir.Warnings.UnknownType do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :unknown_type
  def warning(), do: :unknown_type

  @impl Dialyxir.Warning
  @spec format_long({String.t(), String.t(), String.t()}) :: String.t()
  def format_long({module, function, arity}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)

    "Unknown type: #{pretty_module}.#{function}/#{arity}."
  end
end
