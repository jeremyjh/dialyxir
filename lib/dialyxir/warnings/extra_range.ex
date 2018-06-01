defmodule Dialyxir.Warnings.ExtraRange do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :extra_range
  def warning(), do: :extra_range

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short([module, function, arity, _extra_ranges, _signature_range]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)

    "@spec for #{pretty_module}.#{function}/#{arity} has more types " <>
      "than returned by function."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, arity, extra_ranges, signature_range]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_extra = Dialyxir.PrettyPrint.pretty_print_type(extra_ranges)
    pretty_signature = Dialyxir.PrettyPrint.pretty_print_type(signature_range)

    """
    Type specification has too many types.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Extra type:
    #{pretty_extra}

    Success typing:
    #{pretty_signature}
    """
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    """
    The @spec says the function returns more types than the function actually returns.

    Example:

    defmodule Example do
      @spec ok() :: :ok | :error
      def ok() do
        :ok
      end
    end
    """
  end
end
