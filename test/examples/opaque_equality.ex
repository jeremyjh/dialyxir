defmodule Dialyxir.Examples.OpaqueEquality do

  defmodule Types do
    @opaque type :: :ok

    @spec ok() :: type()
    def ok() do
      :ok
    end
  end

  def eq_ok() do
    Types.ok() == :ok
  end
end
