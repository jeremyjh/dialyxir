defmodule Verbose.ModuleTree.OpaqueEqualityTypes do
  @opaque type :: :ok

  @spec ok() :: type()
  def ok() do
    :ok
  end
end

defmodule OpaqueEqualityExample do
  def eq_ok() do
    Verbose.ModuleTree.OpaqueEqualityTypes.ok() == :ok
  end
end
