defmodule Dialyxir.Warnings.CallbackSpecTypeMismatch do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :callback_spec_type_mismatch
  def warning(), do: :callback_spec_type_mismatch

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([behaviour, function, arity, success_type, callback_type]) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)
    pretty_success_type = Dialyxir.PrettyPrint.pretty_print_type(success_type)
    pretty_callback_type = Dialyxir.PrettyPrint.pretty_print_type(callback_type)

    """
    The return type #{pretty_success_type} in the specification
    of #{function}/#{arity} is not subtype of #{pretty_callback_type},
    which is the expected return type for the callback of
    the #{pretty_behaviour} behaviour.
    """
  end
end
