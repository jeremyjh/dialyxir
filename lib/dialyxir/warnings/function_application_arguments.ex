defmodule Dialyxir.Warnings.FuncionApplicationArguments do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :fun_app_args
  def warning(), do: :fun_app_args

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([args, type]) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)
    pretty_type = Dialyxir.PrettyPrint.pretty_print(type)

    "Function application with arguments #{pretty_args} will fail " <>
      "since the function has type #{pretty_type}."
  end
end
