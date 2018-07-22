defmodule Dialyxir.Warnings.InvalidContract do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :invalid_contract
  def warning(), do: :invalid_contract

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short([module, function, arity, _signature]) do
    pretty_module = Erlex.PrettyPrint.pretty_print(module)
    "Invalid type specification for function #{pretty_module}.#{function}/#{arity}."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity, signature]) do
    pretty_module = Erlex.PrettyPrint.pretty_print(module)
    pretty_signature = Erlex.PrettyPrint.pretty_print_contract(signature)

    """
    Invalid type specification for function.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Success typing:
    @spec #{function}#{pretty_signature}
    """
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    """
    The @spec for the function does not match the success typing of
    the function.

    Example:

    defmodule Example do
      @spec ok(:error) :: :ok
      def ok(:ok) do
        :ok
      end
    end
    """
  end
end
