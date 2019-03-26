defmodule Dialyxir.Examples.CallbackArgument do
  defmodule Behaviour do
    @callback ok(:ok) :: :ok
  end

  @behaviour Behaviour

  def ok(:error) do
    :ok
  end
end
