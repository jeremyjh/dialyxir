defmodule Dialyxir.Warnings.CallbackArgumentTypeMismatch do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :callback_arg_type_mismatch
  def warning(), do: :callback_arg_type_mismatch

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([behaviour, function, arity, success_type, callback_type]) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)
    pretty_success_type = Dialyxir.PrettyPrint.pretty_print_type(success_type)
    pretty_callback_type = Dialyxir.PrettyPrint.pretty_print_type(callback_type)

    """
    The inferred return type of #{function}/#{arity}
    (#{pretty_success_type}) has nothing in common
    with #{pretty_callback_type}, which is the expected return type
    for the callback of the #{pretty_behaviour} behaviour.
    """
  end

  def format_long([behaviour, function, arity, position, success_type, callback_type]) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)
    pretty_success_type = Dialyxir.PrettyPrint.pretty_print_type(success_type)
    pretty_callback_type = Dialyxir.PrettyPrint.pretty_print_type(callback_type)

    """
    The inferred type for the #{Dialyxir.WarningHelpers.ordinal(position)} argument
    of #{function}/#{arity} (#{pretty_success_type})) is not a supertype of
    #{pretty_callback_type}, which is expected type for this argument
    in the callback of the #{pretty_behaviour} behaviour.
    """
  end
end
