defmodule Dialyxir.Warnings.FunctionApplicationNoFunction do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :fun_app_no_fun
  def warning(), do: :fun_app_no_fun

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short(_) do
    "Function application arity mismatch."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([op, type, arity]) do
    pretty_op = Dialyxir.PrettyPrint.pretty_print(op)
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)

    "Function application will fail since #{pretty_op} :: #{pretty_type} is not a function of arity #{arity}."
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    """
    The function being invoked exists has an arity mismatch.

    Example:

    defmodule Example do
      def ok() do
        fun = fn _ -> :ok end
        fun.()
      end
    end
    """
  end
end
