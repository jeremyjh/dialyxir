defmodule Dialyxir.Examples.ContractWithOpaqueTypes do
  @opaque type :: :ok
end

defmodule Dialyxir.Examples.ContractWithOpaque do
  @spec ok() :: ContractWithOpaqueTypes.type()
  def ok() do
    :ok
  end
end
