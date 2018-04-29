defmodule Dialyxir.Warnings.FunctionApplicationNoFunction do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :fun_app_no_fun
  def warning(), do: :fun_app_no_fun

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([op, type, arity]) do
    "Function application will fail since #{op} :: #{type} is not a function of arity #{arity}."
  end
end
