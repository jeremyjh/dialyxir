defmodule Dialyxir.Warnings.ContractDiff do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :contract_diff
  def warning(), do: :contract_diff

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity, contract, signature]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_contract = Dialyxir.PrettyPrint.pretty_print_type(contract)
    pretty_signature = Dialyxir.PrettyPrint.pretty_print_type(signature)

    """
    Type specification is not equal to the success typing.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Type specification:
    #{pretty_contract}

    Success typing:
    #{pretty_signature}
    """
  end
end
