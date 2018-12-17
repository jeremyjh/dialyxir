defmodule Dialyxir.Dialyzer do
  import Dialyxir.Output, only: [color: 2, info: 1]
  alias String.Chars
  alias Dialyxir.Formatter
  alias Dialyxir.Project
  alias Dialyxir.FilterMap

  defmodule Runner do
    def run(args, filterer) do
      try do
        split_args = [:raw, :format, :list_unused_filters, :halt_exit_status]
        {split, args} = Keyword.split(args, split_args)

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

            split[:raw] ->
              :raw

            true ->
              :dialyxir
          end

        info("Starting Dialyzer")

        args
        |> inspect(label: "dialyzer args", pretty: true)
        |> info

        {duration_ms, result} = :timer.tc(&:dialyzer.run/1, [args])

        formatted_time_elapsed = Formatter.formatted_time(duration_ms)

        filter_map_args = FilterMap.to_args(split)

        case Formatter.format_and_filter(result, filterer, filter_map_args, formatter) do
          {:ok, formatted_warnings, :no_unused_filters} ->
            {:ok, {formatted_time_elapsed, formatted_warnings, ""}}

          {:warn, formatted_warnings, {:unused_filters_present, formatted_unnecessary_skips}} ->
            {:ok, {formatted_time_elapsed, formatted_warnings, formatted_unnecessary_skips}}

          {:warn, formatted_warnings, :no_unused_filters} ->
            {:ok, {formatted_time_elapsed, formatted_warnings, ""}}

          {:error, _formatted_warnings, {:unused_filters_present, formatted_unnecessary_skips}} ->
            {:error, {"unused filters present", formatted_unnecessary_skips}}
        end
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
      {:ok, {time, [], formatted_unnecessary_skips}} ->
        {:ok, @success_return_code, [time, formatted_unnecessary_skips, @success_msg]}

      {:ok, {time, result, formatted_unnecessary_skips}} ->
        warnings = Enum.map(result, &color(&1, :red))

        {:warn, @warning_return_code,
         [time] ++ warnings ++ [formatted_unnecessary_skips, @warnings_msg]}

      {:warn, {time, result, formatted_unnecessary_skips}} ->
        warnings = Enum.map(result, &color(&1, :red))

        {:warn, @warning_return_code,
         [time] ++ warnings ++ [formatted_unnecessary_skips, @warnings_msg]}

      {:error, {msg, formatted_unnecessary_skips}} ->
        {:error, @error_return_code, [color(formatted_unnecessary_skips, :red), color(msg, :red)]}

      {:error, msg} ->
        {:error, @error_return_code, [color(msg, :red)]}
    end
  end
end
