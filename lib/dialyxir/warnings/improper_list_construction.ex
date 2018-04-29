defmodule Dialyxir.Warnings.ImproperListConstruction do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :improper_list_constr
  def warning(), do: :improper_list_constr

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([tl_type]) do
    pretty_type = Dialyxir.PrettyPrint.pretty_print(tl_type)
    "Cons will produce an improper list since its 2nd argument is #{pretty_type}."
  end
end
