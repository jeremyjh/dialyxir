defmodule CallbackSpecArgumentExampleBehaviour do
  @callback ok(:ok) :: :ok
end

defmodule CallbackSpecArgumentExample do
  @behaviour CallbackSpecArgumentExampleBehaviour

  @spec ok(:error) :: :ok
  def ok(:ok) do
    :ok
  end
end
