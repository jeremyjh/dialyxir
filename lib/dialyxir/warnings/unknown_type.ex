defmodule Dialyxir.Warnings.UnknownType do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :unknown_type
  def warning(), do: :unknown_type

  @impl Dialyxir.Warning
  @spec format_short({String.t(), String.t(), String.t()}) :: String.t()
  def format_short({_module, function, _arity}) do
    "Unknown type: #{function}."
  end

  @impl Dialyxir.Warning
  @spec format_long({String.t(), String.t(), String.t()}) :: String.t()
  def format_long({module, function, arity}) do
    pretty_module = Erlex.pretty_print(module)

    "Unknown type: #{pretty_module}.#{function}/#{arity}."
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    """
    Spec references a missing @type.

    Example:

    defmodule Missing do
    end

    defmodule Example do
      @spec ok(Missing.t()) :: :ok
      def ok(_) do
        :ok
      end
    end
    """
  end
end
