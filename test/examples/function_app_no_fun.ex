defmodule Dialyxir.Examples.FunctionApplicationNoFun do
  def ok() do
    fun = fn _ -> :ok end
    fun.()
  end
end
