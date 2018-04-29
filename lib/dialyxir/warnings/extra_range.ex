defmodule Dialyxir.Warnings.ExtraRange do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :extra_range
  def warning(), do: :extra_range

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity, extra_ranges, signature_range]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)

    "The specification for #{pretty_module}.#{function}/#{arity} states that the function might also return #{
      extra_ranges
    } but the inferred return is #{signature_range}."
  end
end
