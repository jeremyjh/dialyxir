defmodule Dialyxir.Examples.FunctionApplicationArgs do
  def f do
    fn :a, [] -> :ok end
  end

  def ok() do
    fun = f()
    fun.(:b, [])
  end
end
