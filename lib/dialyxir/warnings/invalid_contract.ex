defmodule Dialyxir.Warnings.InvalidContract do
  @moduledoc """
  The @spec for the function does not match the success typing of the
  function.

  ## Example

      defmodule Example do
        @spec process(:error) :: :ok
        def process(:ok) do
          :ok
        end
      end

  The @spec in this case claims that the function accepts a parameter
  :error but the function head only accepts :ok, resulting in the
  mismatch.
  """

  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :invalid_contract
  def warning(), do: :invalid_contract

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short([_module, function | _]) do
    "Invalid type specification for function #{function}."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity, signature]) do
    format_long([module, function, arity, nil, signature])
  end

  def format_long([module, function, arity, _args, spec, success_typing]) do
    pretty_module = Erlex.pretty_print(module)
    pretty_success_typing = Erlex.pretty_print_contract(success_typing)
    pretty_spec = Erlex.pretty_print_contract(spec)

    """
    The @spec for the function does not match the success typing of the function.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Success typing:
    #{pretty_success_typing}

    But the spec is:
    #{pretty_spec}
    """
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    @moduledoc
  end
end
