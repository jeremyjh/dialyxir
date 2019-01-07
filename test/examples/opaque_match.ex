defmodule OpaqueMatchExampleStruct do
  defstruct [:opaque]

  @opaque t :: %__MODULE__{}

  @spec opaque() :: t
  def opaque() do
    %__MODULE__{}
  end
end

defmodule OpaqueMatchExample do
  @spec error() :: :error
  def error() do
    %{opaque: _} = OpaqueMatchExampleStruct.opaque()
    :error
  end
end
