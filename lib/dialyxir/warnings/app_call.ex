defmodule Dialyxir.Warnings.AppCall do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :app_call
  def warning(), do: :app_call

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, args, culprit, expected_type, actual_type]) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)

    "The call #{pretty_module}.#{function}#{pretty_args} requires that " <>
      "#{culprit} is of type #{expected_type} not #{actual_type}."
  end
end
