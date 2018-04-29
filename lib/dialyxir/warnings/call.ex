defmodule Dialyxir.Warnings.Call do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :call
  def warning(), do: :call

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([
        module,
        function,
        args,
        arg_positions,
        fail_reason,
        signature_args,
        signature_return,
        contract
      ]) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)

    call_string =
      Dialyxir.WarningHelpers.call_or_apply_to_string(
        arg_positions,
        fail_reason,
        signature_args,
        signature_return,
        contract
      )

    "The call #{pretty_module}.#{function}#{pretty_args} #{call_string}."
  end
end
