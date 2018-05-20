defmodule Dialyxir.Warnings.UnmatchedReturn do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :unmatched_return
  def warning(), do: :unmatched_return

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short(_) do
    "Expression produces multiple types but none are matched."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([type]) do
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)

    """
    Expression produces a value of type:

    #{pretty_type}

    but this value is unmatched.
    """
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    """
    The invoked expression returns a union of types and the call does
    not match on its return types using e.g. a case or wildcard.

    Example:

    defmodule Example do
      require Integer

      def ok() do
        n = :rand.uniform(100)

        multiple_returns(n)

        :ok
      end

      defp multiple_returns(n) do
        if Integer.is_even(n) do
          :ok
        else
          {:error, "error"}
        end
      end
    end

    This would NOT result in a warning:

    defmodule Example do
      require Integer

      def ok() do
        n = :rand.uniform(100)

        multiple_returns(n)

        :ok
      end

      defp multiple_returns(n) do
        if Integer.is_even(n) do
          :ok
        else
          :error
        end
      end
    end
    """
  end
end
