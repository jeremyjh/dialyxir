defmodule Dialyxir.Examples.CallbackSpecArgument do
  defmodule Behaviour do
    @callback ok(:ok) :: :ok
  end

  @behaviour Behaviour

  @spec ok(:error) :: :ok
  def ok(:ok) do
    :ok
  end
end
