defmodule Dialyxir.Formatter.Raw do
  @moduledoc false

  def format(warning) do
    inspect(warning, limit: :infinity)
  end
end
