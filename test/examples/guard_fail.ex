defmodule Dialyxir.Examples.GuardFail do
  def ok() do
    ok(0)
  end

  defp ok(n) when n > 1 do
    :ok
  end
end
