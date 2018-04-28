defmodule Dialyxir.Warnings.ExactEquality do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :exact_eq
  def warning(), do: :exact_eq

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([[type1, op, type2]]) do
    "The test #{type1} #{op} #{type2} can never evaluate to 'true'."
  end
end
