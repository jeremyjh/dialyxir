defmodule Dialyxir.Warnings.ContractSupertype do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :contract_supertype
  def warning(), do: :contract_supertype

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity, contract, signature]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_contract = Dialyxir.PrettyPrint.pretty_print_contract(contract)
    pretty_signature = Dialyxir.PrettyPrint.pretty_print_contract(signature)

    """
    Type specification is a supertype of the success typing.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Type specification:
    @spec #{function}#{pretty_contract}

    Success typing:
    @spec #{function}#{pretty_signature}
    """
  end
end
