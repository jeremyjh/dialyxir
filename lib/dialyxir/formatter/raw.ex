defmodule Dialyxir.Formatter.Raw do
  @moduledoc false

  @behaviour Dialyxir.Formatter

  @impl Dialyxir.Formatter
  def format(warning) do
    inspect(warning, limit: :infinity)
  end
end
