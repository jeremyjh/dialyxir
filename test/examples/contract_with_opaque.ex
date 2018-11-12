defmodule ContractWithOpaqueTypes do
  @opaque type :: :ok
end

defmodule ContractWithOpaqueExample do
  @spec ok() :: ContractWithOpaqueTypes.type()
  def ok() do
    :ok
  end
end
