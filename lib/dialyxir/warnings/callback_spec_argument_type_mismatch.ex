defmodule Dialyxir.Warnings.CallbackSpecArgumentTypeMismatch do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :callback_spec_arg_type_mismatch
  def warning(), do: :callback_spec_arg_type_mismatch

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([behaviour, function, arity, position, success_type, callback_type]) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)
    pretty_success_type = Dialyxir.PrettyPrint.pretty_print_type(success_type)
    pretty_callback_type = Dialyxir.PrettyPrint.pretty_print_type(callback_type)

    """
    The specified type for the #{Dialyxir.WarningHelpers.ordinal(position)} argument
    of #{function}/#{arity} (#{pretty_success_type}) is not a supertype
    of #{pretty_callback_type}, which is the expected type for this
    argment in the callback of the #{pretty_behaviour} behaviour.
    """
  end
end
