defmodule FunctionApplicationNoFunExample do
  def ok() do
    fun = fn _ -> :ok end
    fun.()
  end
end
