defmodule Dialyxir.Warnings.NoReturn do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :no_return
  def warning(), do: :no_return

  @impl Dialyxir.Warning
  @spec format_long([String.t() | atom]) :: String.t()
  def format_long([type | name]) do
    name_string =
      case name do
        [] ->
          "The created fun "

        [function, arity] ->
          "Function #{function}/#{arity} "
      end

    type_string =
      case type do
        :no_match ->
          "has no clauses that will ever match."

        :only_explicit ->
          "only terminates with explicit exception."

        :only_normal ->
          "has no local return."

        :both ->
          "has no local return."
      end

    name_string <> type_string
  end
end
