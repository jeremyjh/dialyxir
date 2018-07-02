defmodule Dialyxir.Warnings.MissingRange do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :missing_range
  def warning(), do: :missing_range

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short(_) do
    "Type specification is missing types returned by function."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity, extra_ranges, contract_range]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_contract_range = Dialyxir.PrettyPrint.pretty_print_contract(contract_range)
    pretty_extra_ranges = Dialyxir.PrettyPrint.pretty_print_contract(extra_ranges)

    """
    Type specification is missing types returned by function.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Type specification return types:
    #{pretty_contract_range}

    Extra types in success typing:
    #{pretty_extra_ranges}
    """
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    Dialyxir.Warning.default_explain()
  end
end
