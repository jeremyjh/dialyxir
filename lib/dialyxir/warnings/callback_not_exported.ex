defmodule Dialyxir.Warnings.CallbackNotExported do
  @moduledoc """
  Module implements a behaviour, but does not export some of its
  callbacks.

  ## Example
      defmodule Example do
        @behaviour GenServer

        def init(_) do
          :ok
        end

        # OK. No warning.
        def handle_all(_request, _from, state) do
          {:noreply, state}
        end

        # Not exported. Should be a warning.
        @spec handle_cast(any(), any()) :: binary()
        defp handle_cast(_request, _state) do
          "abc"
        end

        # Not exported and conflicting arguments and return value. No warning
        # since format_status/1 is an optional callback.
        @spec format_status(binary()) :: binary()
        def format_status(bin) when is_binary(bin) do
          bin
        end
      end
  """

  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :callback_not_exported
  def warning(), do: :callback_not_exported

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short(args), do: format_long(args)

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([behaviour, function, arity]) do
    pretty_behaviour = Erlex.pretty_print(behaviour)

    "Callback function #{function}/#{arity} exists but is not exported (behaviour #{pretty_behaviour})."
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    @moduledoc
  end
end
