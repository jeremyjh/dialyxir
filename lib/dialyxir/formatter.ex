defmodule Dialyxir.Formatter do
  @moduledoc """
  Elixir-friendly dialyzer formatter.

  Wrapper around normal Dialyzer warning messages that provides
  example output for error messages.
  """
  import Dialyxir.Output

  alias Dialyxir.FilterMap

  @type warning() ::
          {tag :: term(), {file :: Path.t(), location :: :erl_anno.location()}, {atom(), list()}}

  @type t() :: module()

  @callback format(warning()) :: String.t()

  def formatted_time(duration_us) do
    minutes = div(duration_us, 60_000_000)
    seconds = (rem(duration_us, 60_000_000) / 1_000_000) |> Float.round(2)
    "done in #{minutes}m#{seconds}s"
  end

  @spec format_and_filter([tuple], module, Keyword.t(), t(), boolean()) :: tuple
  def format_and_filter(
        warnings,
        filterer,
        filter_map_args,
        formatter,
        quiet_with_result? \\ false
      )

  def format_and_filter(warnings, filterer, filter_map_args, formatter, quiet_with_result?) do
    filter_map = filterer.filter_map(filter_map_args)

    {filtered_warnings, filter_map} = filter_warnings(warnings, filterer, filter_map)

    formatted_warnings =
      filtered_warnings
      |> filter_legacy_warnings(filterer)
      |> Enum.map(&formatter.format/1)
      |> Enum.uniq()

    show_count_skipped(warnings, formatted_warnings, filter_map, quiet_with_result?)
    formatted_unnecessary_skips = format_unnecessary_skips(filter_map)

    result(formatted_warnings, filter_map, formatted_unnecessary_skips)
  end

  defp result(formatted_warnings, filter_map, formatted_unnecessary_skips) do
    cond do
      FilterMap.unused_filters?(filter_map) && filter_map.unused_filters_as_errors? ->
        {:error, formatted_warnings, {:unused_filters_present, formatted_unnecessary_skips}}

      FilterMap.unused_filters?(filter_map) ->
        {:warn, formatted_warnings, {:unused_filters_present, formatted_unnecessary_skips}}

      true ->
        {:ok, formatted_warnings, :no_unused_filters}
    end
  end

  defp show_count_skipped(warnings, filtered_warnings, filter_map, quiet_with_result?) do
    warnings_count = Enum.count(warnings)
    filtered_warnings_count = Enum.count(filtered_warnings)
    skipped_count = warnings_count - filtered_warnings_count
    unnecessary_skips_count = count_unnecessary_skips(filter_map)

    message =
      "Total errors: #{warnings_count}, Skipped: #{skipped_count}, Unnecessary Skips: #{unnecessary_skips_count}"

    if quiet_with_result? do
      Mix.shell(Mix.Shell.IO)
      info(message)
      Mix.shell(Mix.Shell.Quiet)
    else
      info(message)
    end

    :ok
  end

  defp format_unnecessary_skips(filter_map = %FilterMap{list_unused_filters?: true}) do
    unused_filters = FilterMap.unused_filters(filter_map)

    if Enum.empty?(unused_filters) do
      ""
    else
      unused_filters = Enum.map_join(unused_filters, "\n", &inspect/1)
      "Unused filters:\n#{unused_filters}"
    end
  end

  defp format_unnecessary_skips(_) do
    ""
  end

  defp count_unnecessary_skips(filter_map) do
    filter_map.counters
    |> Enum.filter(&FilterMap.unused?/1)
    |> Enum.count()
  end

  defp filter_warnings(warnings, filterer, filter_map) do
    {warnings, filter_map} =
      Enum.map_reduce(warnings, filter_map, &filter_warning(filterer, &1, &2))

    warnings = Enum.reject(warnings, &is_nil/1)
    {warnings, filter_map}
  end

  defp filter_warning(filterer, {_, {_file, _line}, {warning_type, _args}} = warning, filter_map) do
    if Map.has_key?(Dialyxir.Warnings.warnings(), warning_type) do
      {skip?, matching_filters} =
        try do
          filterer.filter_warning?(warning, filter_map)
        rescue
          _ ->
            {false, []}
        catch
          _ ->
            {false, []}
        end

      filter_map =
        Enum.reduce(matching_filters, filter_map, fn filter, filter_map ->
          FilterMap.inc(filter_map, filter)
        end)

      if skip? do
        {nil, filter_map}
      else
        {warning, filter_map}
      end
    else
      {warning, filter_map}
    end
  end

  defp filter_legacy_warnings(warnings, filterer) do
    Enum.reject(warnings, fn warning ->
      formatted_warnings =
        warning
        |> Dialyxir.Formatter.Dialyzer.format()
        |> List.wrap()

      Enum.empty?(filterer.filter_legacy_warnings(formatted_warnings))
    end)
  end
end
