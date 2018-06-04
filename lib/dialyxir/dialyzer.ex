defmodule Dialyxir.Dialyzer do
  import Dialyxir.Output, only: [color: 2]
  alias String.Chars
  alias Dialyxir.Formatter
  alias Dialyxir.Project

  defmodule Runner do
    def run(args, filterer) do
      try do
        {split, args} = Keyword.split(args, [:raw, :format, :explain])
        formatter =
          cond do
            split[:format] == "dialyzer" ->
              :dialyzer

            split[:format] == "dialyxir" ->
              :dialyxir

            split[:format] == "raw" ->
              :raw

            split[:format] == "short" ->
              :short

            split[:explain] ->
              String.to_existing_atom(split[:explain])

            split[:raw] ->
              :raw

            true ->
              :dialyxir
        end
        {duration_ms, result} = :timer.tc(&:dialyzer.run/1, [args])

        formatted_time_elapsed = Formatter.formatted_time(duration_ms)
        formatted_warnings = Formatter.format_and_filter(result, filterer, formatter)
        {:ok, {formatted_time_elapsed, formatted_warnings}}
      catch
        {:dialyzer_error, msg} ->
          {:error, ":dialyzer.run error: " <> Chars.to_string(msg)}
      end
    end
  end

  @success_msg color("done (passed successfully)", :green)
  @warnings_msg color("done (warnings were emitted)", :yellow)
  @success_return_code 0
  @warning_return_code 2
  @error_return_code 1

  def dialyze(args, runner \\ Runner, filterer \\ Project) do
    case runner.run(args, filterer) do
      {:ok, {time, []}} ->
        {:ok, @success_return_code, [time, @success_msg]}

      {:ok, {time, result}} ->
        warnings = Enum.map(result, &color(&1, :red))
        {:warn, @warning_return_code, [time] ++ warnings ++ [@warnings_msg]}

      {:error, msg} ->
        {:error, @error_return_code, [color(msg, :red)]}
    end
  end
end
