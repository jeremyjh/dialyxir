defmodule Dialyxir.Output do
  alias IO.ANSI

  @warning_regex ~r/\w+.ex:\d+:/

  def format(input) do
    if ANSI.enabled? do
      String.split(input, "\n")
      |> Enum.map_join("\n", &colorize(&1))
    else
      input
    end
  end

  defp colorize(line, color), do: color <> line <> ANSI.reset()

  defp colorize("done (passed successfully)" = line), do: colorize(line, ANSI.green())

  defp colorize("done (warnings were emitted)" = line), do: colorize(line, ANSI.yellow())

  defp colorize(line) do
    if String.match?(line, @warning_regex) do
      colorize(line, ANSI.red())
    else
      line
    end
  end
end
