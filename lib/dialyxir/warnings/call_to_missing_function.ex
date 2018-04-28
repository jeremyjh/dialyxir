defmodule Dialyxir.Warnings.CallToMissingFunction do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :call_to_missing
  def warning(), do: :call_to_missing

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([module, function, arity]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    "Call to missing or private function #{pretty_module}.#{function}/#{arity}."
  end
end
