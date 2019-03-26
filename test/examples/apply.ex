defmodule Dialyxir.Examples.Apply do
  def ok() do
    fun = fn :ok -> :ok end
    fun.(:error)
  end
end
