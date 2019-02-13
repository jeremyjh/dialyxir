defmodule Dialyxir.Warnings.InvalidContract do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :invalid_contract
  def warning(), do: :invalid_contract

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short([module, function, arity, _signature]) do
    pretty_module = Erlex.pretty_print(module)
    "The @spec for the function #{pretty_module}.#{function}/#{arity} does not match the success typing of the function."
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

    This does not match because the success typing (what actually happens) is
    that the function returns `:ok`, if and only if the function receives `:ok`,
    but the @spec of the function says that it receives `:error` and returns
    `:ok`, but actually when the function receives `:error` it throws a
    `FunctionClauseError`
    """
  end
end
