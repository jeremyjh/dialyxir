defmodule Dialyxir.Warnings.GuardFail do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :guard_fail
  def warning(), do: :guard_fail

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short(_) do
    "The guard clause can never succeed."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([]) do
    "The guard clause can never succeed."
  end

  def format_long([guard, args]) do
    pretty_args = Erlex.pretty_print_args(args)

    """
    The guard test:

    #{guard}#{pretty_args}

    can never succeed.
    """
  end

  def format_long([arg1, infix, arg2]) do
    pretty_arg1 = Erlex.pretty_print_type(arg1)
    pretty_arg2 = Erlex.pretty_print_args(arg2)
    pretty_infix = Erlex.pretty_print_infix(infix)

    """
    The guard clause:

    #{pretty_arg1}

    #{pretty_infix}

    #{pretty_arg2}

    can never succeed.
    """
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    """
    The function guard either presents an impossible guard or the only
    calls will never succeed against the guards.

    Example:

    defmodule Example do
      def ok() do
        ok(0)
      end

      defp ok(n) when n > 1 do
        :ok
      end
    end

    or

    defmodule Example do
      def ok() when 0 > 1 do
        :ok
      end
    end
    """
  end
end
