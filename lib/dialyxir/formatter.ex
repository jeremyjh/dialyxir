defmodule Dialyxir.Formatter do
  @moduledoc """
  Elixir-friendly dialyzer formatter.

  Wrapper around normal Dialyzer warning messages that provides
  example output for error messages.
  """
  import Dialyxir.Output, only: [info: 1]

  @warnings Enum.into(
              [
                Dialyxir.Warnings.AppCall,
                Dialyxir.Warnings.Apply,
                Dialyxir.Warnings.BinaryConstruction,
                Dialyxir.Warnings.Call,
                Dialyxir.Warnings.CallToMissingFunction,
                Dialyxir.Warnings.CallWithOpaque,
                Dialyxir.Warnings.CallWithoutOpaque,
                Dialyxir.Warnings.CallbackArgumentTypeMismatch,
                Dialyxir.Warnings.CallbackInfoMissing,
                Dialyxir.Warnings.CallbackMissing,
                Dialyxir.Warnings.CallbackSpecArgumentTypeMismatch,
                Dialyxir.Warnings.CallbackSpecTypeMismatch,
                Dialyxir.Warnings.CallbackTypeMismatch,
                Dialyxir.Warnings.ContractDiff,
                Dialyxir.Warnings.ContractSubtype,
                Dialyxir.Warnings.ContractSupertype,
                Dialyxir.Warnings.ContractWithOpaque,
                Dialyxir.Warnings.ExactEquality,
                Dialyxir.Warnings.ExtraRange,
                Dialyxir.Warnings.FuncionApplicationArguments,
                Dialyxir.Warnings.FunctionApplicationNoFunction,
                Dialyxir.Warnings.GuardFail,
                Dialyxir.Warnings.GuardFailPattern,
                Dialyxir.Warnings.ImproperListConstruction,
                Dialyxir.Warnings.InvalidContract,
                Dialyxir.Warnings.NegativeGuardFail,
                Dialyxir.Warnings.NoReturn,
                Dialyxir.Warnings.OpaqeGuard,
                Dialyxir.Warnings.OpaqueEquality,
                Dialyxir.Warnings.OpaqueMatch,
                Dialyxir.Warnings.OpaqueNonequality,
                Dialyxir.Warnings.OpaqueTypeTest,
                Dialyxir.Warnings.OverlappingContract,
                Dialyxir.Warnings.PatternMatch,
                Dialyxir.Warnings.PatternMatchCovered,
                Dialyxir.Warnings.RaceCondition,
                Dialyxir.Warnings.RecordConstruction,
                Dialyxir.Warnings.RecordMatching,
                Dialyxir.Warnings.UnknownBehaviour,
                Dialyxir.Warnings.UnknownFunction,
                Dialyxir.Warnings.UnknownType,
                Dialyxir.Warnings.UnmatchedReturn,
                Dialyxir.Warnings.UnusedFunction
              ],
              %{},
              fn warning -> {warning.warning(), warning} end
            )

  def formatted_time(duration_ms) do
    minutes = div(duration_ms, 6_000_000)
    seconds = (rem(duration_ms, 6_000_000) / 1_000_000) |> Float.round(2)
    "done in #{minutes}m#{seconds}s"
  end

  def format_and_filter(warnings, _, :raw) do
    Enum.map(warnings, &inspect/1)
  end

  def format_and_filter(warnings, filterer, :dialyxir) do
    divider = String.duplicate("_", 80)

    formatted_warnings =
      warnings
      |> filter_warnings(filterer)
      |> filter_legacy_warnings(filterer)
      |> Enum.map(fn warning ->
        message =
          warning
          |> format_warning(:dialyxir)
          |> String.replace_trailing("\n", "")

        message <> "\n" <> divider
      end)

    show_count_skipped(warnings, formatted_warnings)

    formatted_warnings
  end

  def format_and_filter(warnings, filterer, :dialyzer) do
    filtered_warnings =
      warnings
      |> filter_warnings(filterer)
      |> filter_legacy_warnings(filterer)
      |> Enum.map(fn warning ->
        warning
        |> format_warning(:dialyzer)
        |> String.replace_trailing("\n", "")
      end)

    show_count_skipped(warnings, filtered_warnings)

    filtered_warnings
  end

  def format_and_filter(warnings, filterer, :short) do
    warnings
    |> filter_warnings(filterer)
    |> filter_legacy_warnings(filterer)
    |> Enum.map(&format_warning(&1, :short))
  end

  def format_and_filter(_, _, warning_name) do
    warning = Map.get(@warnings, warning_name)
    [warning.explain()]
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

  defp show_count_skipped(warnings, filtered_warnings) do
    warnings_count = Enum.count(warnings)
    filtered_warnings_count = Enum.count(filtered_warnings)
    skipped_count = warnings_count - filtered_warnings_count
    info("Total errors: #{warnings_count}, Skipped: #{skipped_count}")

    :ok
  end

  defp warning(warning_name) do
    if Map.has_key?(@warnings, warning_name) do
      Map.get(@warnings, warning_name)
    else
      throw({:error, :unknown_warning, warning_name})
    end
  end

  defp filter_warnings(warnings, filterer) do
    Enum.reject(warnings, fn warning = {_, {file, line}, {warning_type, _}} ->
      filterer.filter_warning?(
        {to_string(file), warning_type, line, format_warning(warning, :short)}
      )
    end)
  end

  defp filter_legacy_warnings(warnings, filterer) do
    Enum.reject(warnings, fn warning ->
      formatted_warnings =
        warning
        |> format_warning(:dialyzer)
        |> List.wrap()

      Enum.empty?(filterer.filter_warnings(formatted_warnings))
    end)
  end
end
