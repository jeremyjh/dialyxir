defmodule Dialyxir.Dialyzer do
  import Dialyxir.Output
  alias String.Chars
  alias Dialyxir.Formatter
  alias Dialyxir.Project
  alias Dialyxir.FilterMap

  defmodule Runner do
    @dialyxir_args [
      :raw,
      :format,
      :list_unused_filters,
      :ignore_exit_status,
      :quiet_with_result
    ]

    def run(args, filterer) do
      try do
        {split, args} = Keyword.split(args, @dialyxir_args)

        quiet_with_result? = split[:quiet_with_result]

        formatter =
          cond do
            split[:format] == "dialyzer" ->
              Dialyxir.Formatter.Dialyzer

            split[:format] == "dialyxir" ->
              Dialyxir.Formatter.Dialyxir

            split[:format] == "github" ->
              Dialyxir.Formatter.Github

            split[:format] == "ignore_file" ->
              Dialyxir.Formatter.IgnoreFile

            split[:format] == "ignore_file_strict" ->
              Dialyxir.Formatter.IgnoreFileStrict

            split[:format] == "raw" ->
              Dialyxir.Formatter.Raw

            split[:format] == "short" ->
              Dialyxir.Formatter.Short

            split[:raw] ->
              Dialyxir.Formatter.Raw

            true ->
              Dialyxir.Formatter.Dialyxir
          end

        info("Starting Dialyzer")

        args
        |> inspect(label: "dialyzer args", pretty: true, limit: 8)
        |> info

        {duration_us, result} = :timer.tc(&:dialyzer.run/1, [args])

        formatted_time_elapsed = Formatter.formatted_time(duration_us)

        filter_map_args = FilterMap.to_args(split)

        case Formatter.format_and_filter(
               result,
               filterer,
               filter_map_args,
               formatter,
               quiet_with_result?
             ) do
          {:ok, formatted_warnings, :no_unused_filters} ->
            {:ok, {formatted_time_elapsed, formatted_warnings, ""}}

          {:warn, formatted_warnings, {:unused_filters_present, formatted_unnecessary_skips}} ->
            {:ok, {formatted_time_elapsed, formatted_warnings, formatted_unnecessary_skips}}

          {:error, _formatted_warnings, {:unused_filters_present, formatted_unnecessary_skips}} ->
            {:error, {"unused filters present", formatted_unnecessary_skips}}
        end
      catch
        {:dialyzer_error, msg} ->
          {:error, ":dialyzer.run error: " <> Chars.to_string(msg)}
      end
    end
  end

  @success_return_code 0
  @warning_return_code 2
  @error_return_code 1

  def dialyze(args, runner \\ Runner, filterer \\ Project) do
    case runner.run(args, filterer) do
      {:ok, {time, [], formatted_unnecessary_skips}} ->
        {:ok, @success_return_code, [time, formatted_unnecessary_skips, success_msg()]}

      {:ok, {time, result, formatted_unnecessary_skips}} ->
        warnings = Enum.map(result, &color(&1, :red))

        {:warn, @warning_return_code,
         [time] ++ warnings ++ [formatted_unnecessary_skips, warnings_msg()]}

      {:warn, {time, result, formatted_unnecessary_skips}} ->
        warnings = Enum.map(result, &color(&1, :red))

        {:warn, @warning_return_code,
         [time] ++ warnings ++ [formatted_unnecessary_skips, warnings_msg()]}

      {:error, {msg, formatted_unnecessary_skips}} ->
        {:error, @error_return_code, [color(formatted_unnecessary_skips, :red), color(msg, :red)]}

      {:error, msg} ->
        {:error, @error_return_code, [color(msg, :red)]}
    end
  end

  defp success_msg, do: color("done (passed successfully)", :green)

  defp warnings_msg, do: color("done (warnings were emitted)", :yellow)
end
