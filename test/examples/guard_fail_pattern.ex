defmodule GuardFailPatternExample do
  def ok(n = 0) when not n < 1 do
    :ok
  end
end
