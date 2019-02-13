defmodule Dialyxir.Warnings.InvalidContract do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :invalid_contract
  def warning(), do: :invalid_contract

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short([module, function, arity, _signature]) do
    pretty_module = Erlex.pretty_print(module)

    "The @spec for the function #{pretty_module}.#{function}/#{arity} " <>
      "does not match the success typing of the function."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity, signature]) do
    pretty_module = Erlex.pretty_print(module)
    pretty_signature = Erlex.pretty_print_contract(signature)

    """
    The @spec for the function does not match the success typing of the function.

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
      @spec process(:error) :: :ok
      def process(:ok) do
        :ok
      end
    end

    The @spec in this case claims that the function accepts a parameter :error
    but the function head only accepts :ok, resulting in the mismatch.
    """
  end
end
