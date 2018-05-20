defmodule Dialyxir.Warnings.ContractSubtype do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :contract_subtype
  def warning(), do: :contract_subtype

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short(_) do
    "Type specification is a subtype of the success typing."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity, contract, signature]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_contract = Dialyxir.PrettyPrint.pretty_print_contract(contract)
    pretty_signature = Dialyxir.PrettyPrint.pretty_print_contract(signature)

    """
    Type specification is a subtype of the success typing.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Type specification:
    @spec #{function}#{pretty_contract}

    Success typing:
    @spec #{function}#{pretty_signature}
    """
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    """
    The type in the @spec does not completely cover the types returned
    by function.

    Example:

    defmodule Example do
      @spec ok(:ok | :error) :: :ok
      def ok(:ok) do
        :ok
      end

      def ok(:error) do
        :error
      end
    end
    """
  end
end
