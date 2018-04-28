defmodule Dialyxir.Warnings.Apply do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :apply
  def warning(), do: :apply

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([args, arg_positions, fail_reason, signature_args, signature_return, contract]) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)

    call_string =
      Dialyxir.WarningHelpers.call_or_apply_to_string(
        arg_positions,
        fail_reason,
        signature_args,
        signature_return,
        contract
      )

    "Fun application with arguments #{pretty_args} #{call_string}."
  end
end
