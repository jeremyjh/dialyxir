defmodule Dialyxir.Formatter do
  @moduledoc """
  Elixir-friendly dialyzer formatter.

  Wrapper around normal Dialyzer warning messages that provides
  example output for error messages.
  """
  import Dialyxir.Output, only: [info: 1]

  alias Dialyxir.FilterMap

  def formatted_time(duration_us) do
    minutes = div(duration_us, 60_000_000)
    seconds = (rem(duration_us, 60_000_000) / 1_000_000) |> Float.round(2)
    "done in #{minutes}m#{seconds}s"
  end

  def format_and_filter(warnings, _, _filter_map_args, :raw) do
    warnings
    |> Enum.map(&inspect/1)
    |> result()
  end

  def format_and_filter(warnings, filterer, filter_map_args, :dialyxir) do
    divider = String.duplicate("_", 80)
    filter_map = filterer.filter_map(filter_map_args)

    {formatted_warnings, filter_map} = filter_warnings(warnings, filterer, filter_map)

    formatted_warnings =
      formatted_warnings
      |> filter_legacy_warnings(filterer)
      |> Enum.map(fn warning ->
        message =
          warning
          |> format_warning(:dialyxir)
          |> String.replace_trailing("\n", "")

        message <> "\n" <> divider
      end)

    show_count_skipped(warnings, formatted_warnings, filter_map)
    formatted_unnecessary_skips = format_unnecessary_skips(filter_map)

    result(formatted_warnings, filter_map, formatted_unnecessary_skips)
  end

  def format_and_filter(warnings, filterer, filter_map_args, :dialyzer) do
    filter_map = filterer.filter_map(filter_map_args)

    {filtered_warnings, filter_map} = filter_warnings(warnings, filterer, filter_map)

    formatted_warnings =
      filtered_warnings
      |> filter_legacy_warnings(filterer)
      |> Enum.map(fn warning ->
        warning
        |> format_warning(:dialyzer)
        |> String.replace_trailing("\n", "")
      end)

    show_count_skipped(warnings, filtered_warnings, filter_map)
    formatted_unnecessary_skips = format_unnecessary_skips(filter_map)

    result(formatted_warnings, filter_map, formatted_unnecessary_skips)
  end

  def format_and_filter(warnings, filterer, filter_map_args, :short) do
    filter_map = filterer.filter_map(filter_map_args)

    {formatted_warnings, _skip_map} = filter_warnings(warnings, filterer, filter_map)

    formatted_warnings =
      formatted_warnings
      |> filter_legacy_warnings(filterer)
      |> Enum.map(&format_warning(&1, :short))

    formatted_unnecessary_skips = format_unnecessary_skips(filter_map)

    result(formatted_warnings, filter_map, formatted_unnecessary_skips)
  end

  defp result(warnings) do
    if Enum.empty?(warnings) do
      {:ok, [], :no_unused_filters}
    else
      {:warn, warnings, :no_unused_filters}
    end
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

  defp format_warning(warning, :dialyzer) do
    warning
    |> :dialyzer.format_warning(:fullpath)
    |> String.Chars.to_string()
    |> String.replace_trailing("\n", "")
    |> String.replace_suffix("", "\n")
  end

  defp format_warning({_tag, {file, line}, message}, :short) do
    {warning_name, arguments} = message
    base_name = Path.relative_to_cwd(file)

    warning = warning(warning_name)
    string = warning.format_short(arguments)

    "#{base_name}:#{line}:#{warning_name} #{string}"
  end

  defp format_warning(dialyzer_warning = {_tag, {file, line}, message}, :dialyxir) do
    {warning_name, arguments} = message
    base_name = Path.relative_to_cwd(file)

    try do
      warning = warning(warning_name)
      string = warning.format_long(arguments)

      """
      #{base_name}:#{line}:#{warning_name}
      #{string}
      """
    rescue
      e ->
        message = """
        Unknown error occurred: #{inspect(e)}
        """

        wrap_error_message(message, dialyzer_warning)
    catch
      {:error, :unknown_warning, warning_name} ->
        message = """
        Unknown warning:
        #{inspect(warning_name)}
        """

        wrap_error_message(message, dialyzer_warning)

      {:error, :lexing, warning} ->
        message = """
        Failed to lex warning:
        #{inspect(warning)}
        """

        wrap_error_message(message, dialyzer_warning)

      {:error, :parsing, failing_string} ->
        message = """
        Failed to parse warning:
        #{inspect(failing_string)}
        """

        wrap_error_message(message, dialyzer_warning)

      {:error, :pretty_printing, failing_string} ->
        message = """
        Failed to pretty print warning:
        #{inspect(failing_string)}
        """

        wrap_error_message(message, dialyzer_warning)

      {:error, :formatting, code} ->
        message = """
        Failed to format warning:
        #{inspect(code)}
        """

        wrap_error_message(message, dialyzer_warning)
    end
  end

  defp wrap_error_message(message, warning) do
    """
    Please file a bug in https://github.com/jeremyjh/dialyxir/issues with this message.

    #{message}

    Legacy warning:
    #{format_warning(warning, :dialyzer)}
    """
  end

  defp show_count_skipped(warnings, filtered_warnings, filter_map) do
    warnings_count = Enum.count(warnings)
    filtered_warnings_count = Enum.count(filtered_warnings)
    skipped_count = warnings_count - filtered_warnings_count
    unnessary_skips_count = count_unnecessary_skips(filter_map)

    info(
      "Total errors: #{warnings_count}, Skipped: #{skipped_count}, " <>
        "Unnecessary Skips: #{unnessary_skips_count}"
    )

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

  defp warning(warning_name) do
    warnings = Dialyxir.Warnings.warnings()

    if Map.has_key?(warnings, warning_name) do
      Map.get(warnings, warning_name)
    else
      throw({:error, :unknown_warning, warning_name})
    end
  end

  defp filter_warnings(warnings, filterer, filter_map) do
    {warnings, filter_map} =
      Enum.map_reduce(warnings, filter_map, &filter_warning(filterer, &1, &2))

    warnings = Enum.reject(warnings, &is_nil/1)
    {warnings, filter_map}
  end

  defp filter_warning(filterer, warning = {_, {file, line}, {warning_type, _}}, filter_map) do
    if Map.has_key?(Dialyxir.Warnings.warnings(), warning_type) do
      {skip?, matching_filters} =
        filterer.filter_warning?(
          {to_string(file), warning_type, line, format_warning(warning, :short)},
          filter_map
        )

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
        |> format_warning(:dialyzer)
        |> List.wrap()

      Enum.empty?(filterer.filter_legacy_warnings(formatted_warnings))
    end)
  end
end
