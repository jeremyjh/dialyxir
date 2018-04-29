defmodule Dialyxir.Warnings.SpecMissingFunction do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :spec_missing_fun
  def warning(), do: :spec_missing_fun

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    "Contract for function that does not exist: #{pretty_module}.#{function}/#{arity}."
  end
end
