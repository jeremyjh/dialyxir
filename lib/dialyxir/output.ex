defmodule Dialyxir.Output do
  alias IO.ANSI

  def color(text, color) when is_binary(text) do
    case atom_to_ansi(color) do
      :error ->
        text

      {:ok, code} ->
        ANSI.format([code, text, ANSI.reset()])
    end
  end

  defp atom_to_ansi(:red), do: {:ok, ANSI.red()}
  defp atom_to_ansi(:yellow), do: {:ok, ANSI.yellow()}
  defp atom_to_ansi(:green), do: {:ok, ANSI.green()}
  defp atom_to_ansi(_), do: :error

  def info(""), do: :ok
  def info(text), do: Mix.shell().info(text)

  def error(""), do: :ok
  def error(text), do: Mix.shell().error(text)
end
