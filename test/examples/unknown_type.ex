defmodule Dialyxir.Examples.UnknownType do
  defmodule Missing do
  end

  @spec ok(Missing.t()) :: :ok
  def ok(_) do
    :ok
  end
end
