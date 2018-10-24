defmodule CallbackArgumentExampleBehaviour do
  @callback ok(:ok) :: :ok
end

defmodule CallbackArgumentExample do
  @behaviour CallbackArgumentExampleBehaviour

  def ok(:error) do
    :ok
  end
end
