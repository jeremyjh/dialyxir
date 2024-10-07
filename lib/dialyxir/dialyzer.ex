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

    @default_formatter Dialyxir.Formatter.Dialyxir

    def run(args, filterer) do
      try do
        {split, args} = Keyword.split(args, @dialyxir_args)

        quiet_with_result? = split[:quiet_with_result]

        raw_formatters =
          if split[:raw] do
            Enum.uniq(split[:format] ++ ["raw"])
          else
            split[:format]
          end

        formatters =
          case raw_formatters do
            [] -> [@default_formatter]
            raw_formatters -> Enum.map(raw_formatters, &parse_formatter/1)
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
               formatters,
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

    defp parse_formatter("dialyzer"), do: Dialyxir.Formatter.Dialyzer
    defp parse_formatter("dialyxir"), do: Dialyxir.Formatter.Dialyxir
    defp parse_formatter("github"), do: Dialyxir.Formatter.Github
    defp parse_formatter("ignore_file"), do: Dialyxir.Formatter.IgnoreFile
    defp parse_formatter("ignore_file_strict"), do: Dialyxir.Formatter.IgnoreFileStrict
    defp parse_formatter("raw"), do: Dialyxir.Formatter.Raw
    defp parse_formatter("short"), do: Dialyxir.Formatter.Short

    defp parse_formatter(unknown) do
      warning("""
      Unrecognized formatter #{unknown} received. \
      Known formatters are dialyzer, dialyxir, github, ignore_file, ignore_file_strict, raw, and short. \
      Falling back to dialyxir.
      """)

      @default_formatter
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
