defmodule Dialyxir.Examples.ContractWithOpaque do
  defmodule Types do
    @opaque type :: :ok
  end

  @spec ok() :: Types.type()
  def ok() do
    :ok
  end
end
