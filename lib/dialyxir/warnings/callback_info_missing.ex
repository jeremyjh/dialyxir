defmodule Dialyxir.Warnings.CallbackInfoMissing do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :callback_info_missing
  def warning(), do: :callback_info_missing

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([behaviour]) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)

    "Callback info about the #{pretty_behaviour} behaviour is not available."
  end
end
