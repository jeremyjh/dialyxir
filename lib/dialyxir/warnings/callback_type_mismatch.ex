defmodule Dialyxir.Warnings.CallbackTypeMismatch do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :callback_type_mismatch
  def warning(), do: :callback_type_mismatch

  @impl Dialyxir.Warning
  @spec format_long([String.t() | non_neg_integer]) :: String.t()
  def format_long([module, function, arity, fail_type, success_type]) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_fail_type = Dialyxir.PrettyPrint.pretty_print_type(fail_type)
    pretty_success_type = Dialyxir.PrettyPrint.pretty_print_contract(success_type)

    """
    Callback mismatch for @callback #{pretty_module}.#{function}/#{arity}.

    Expecred type:
    #{pretty_success_type}

    Actual type:
    #{pretty_fail_type}
    """
  end
end
