defmodule Dialyxir.Warnings.InvalidContract do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :invalid_contract
  def warning(), do: :invalid_contract

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([module, function, arity, signature]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_signature = Dialyxir.PrettyPrint.pretty_print_contract(signature)

    """
    Invalid type specification for function.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Success typing:
    @spec #{function}#{pretty_signature}
    """
  end
end
