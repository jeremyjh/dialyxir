defmodule Dialyxir.Warnings.GuardFail do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :guard_fail
  def warning(), do: :guard_fail

  @impl Dialyxir.Warning
  @spec format_long(any) :: String.t()
  def format_long([]) do
    "Clause guard cannot succeed."
  end

  def format_long([guard, args]) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)

    """
    Guard test:
    #{guard}#{pretty_args}

    can never succeed.
    """
  end

  def format_long([arg1, infix, arg2]) do
    "Guard test #{arg1} #{infix} #{arg2} can never succeed."
  end
end
