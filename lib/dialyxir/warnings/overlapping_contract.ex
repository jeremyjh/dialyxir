defmodule Dialyxir.Warnings.OverlappingContract do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :overlapping_contract
  def warning(), do: :overlapping_contract

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)

    """
    Overloaded contract for #{pretty_module}.#{function}/#{arity} has overlapping domains;
    such contracts are currently unsupported and are simply ignored.
    """
  end
end
