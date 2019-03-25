
defmodule Dialyxir.Examples.OpaqueMatch do
  defmodule Struct do
    defstruct [:opaque]

    @opaque t :: %__MODULE__{}

    @spec opaque() :: t
    def opaque() do
      %__MODULE__{}
    end
  end

  @spec error() :: :error
  def error() do
    %{opaque: _} = Struct.opaque()
    :error
  end
end
