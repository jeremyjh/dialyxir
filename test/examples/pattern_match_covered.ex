defmodule PatternMuchCoveredExample do
  def ok() do
    unmatched(:error)
  end

  defp unmatched(_), do: :ok

  defp unmatched(:error), do: :error
end
