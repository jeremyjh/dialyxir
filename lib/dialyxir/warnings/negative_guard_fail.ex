defmodule Dialyxir.Warnings.NegativeGuardFail do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :neg_guard_fail
  def warning(), do: :neg_guard_fail

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short(_) do
    "Guard test can never succeed."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([guard, args]) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)

    """
    Guard test:
    not #{guard}#{pretty_args}

    can never succeed.
    """
  end

  def format_long([arg1, infix, arg2]) do
    """
    Guard test:
    not #{arg1} #{infix} #{arg2}

    can never succeed.
    """
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    Dialyxir.Warning.default_explain()
  end
end
