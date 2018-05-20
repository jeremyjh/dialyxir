defmodule Dialyxir.Formatter do
  @moduledoc """
  Elixir-friendly dialyzer formatter.

  Wrapper around normal Dialyzer warning messages that provides
  example output for error messages.
  """

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
      |> Enum.reject(fn warning ->
        formatted_warnings =
          warning
          |> format_warning(:dialyzer)
          |> List.wrap()

        Enum.empty?(filterer.filter_warnings(formatted_warnings))
      end)
      |> Enum.map(fn warning ->
        message =
          try do
            format_warning(warning, :dialyxir)
          catch
            {:error, :message, warning} ->
              """
              Please file a bug in https://github.com/jeremyjh/dialyxir/pull/118 with this message.

              Failed to parse warning:
              #{inspect(warning)}

              Legacy warning:
              #{format_warning(warning, :dialyzer)}
              """

            {:error, :parsing, failing_string} ->
              """
              Please file a bug in https://github.com/jeremyjh/dialyxir/pull/118 with this message.

              Failed to parse part of warning:
              #{inspect(warning)}

              Failing part:
              #{failing_string}

              Legacy warning:
              #{format_warning(warning, :dialyzer)}
              """
          end

        message <> divider
      end)

    show_count_skipped(warnings, formatted_warnings)

    formatted_warnings
  end

  def format_and_filter(warnings, filterer, :dialyzer) do
    formatted_warnings = Enum.map(warnings, &format_warning(&1, :dialyzer))

    filtered_warnings = filterer.filter_warnings(formatted_warnings)
    show_count_skipped(warnings, filtered_warnings)

    filtered_warnings
  end

  def format_and_filter(warnings, filterer, :short) do
    warnings
    |> Enum.reject(fn warning ->
      formatted_warnings =
        warning
        |> format_warning(:dialyzer)
        |> List.wrap()

      Enum.empty?(filterer.filter_warnings(formatted_warnings))
    end)
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
  end

  defp format_warning({_tag, {file, line}, message}, :short) do
    {warning_name, arguments} = message
    base_name = Path.relative_to_cwd(file)

    string =
      if Map.has_key?(@warnings, warning_name) do
        warning = Map.get(@warnings, warning_name)
        warning.format_short(arguments)
      else
        throw({:error, :message, message})
      end

    "#{base_name}:#{line}:#{warning_name} #{string}"
  end

  defp format_warning({_tag, {file, line}, message}, :dialyxir) do
    {warning_name, arguments} = message
    base_name = Path.relative_to_cwd(file)

    string =
      if Map.has_key?(@warnings, warning_name) do
        warning = Map.get(@warnings, warning_name)
        warning.format_long(arguments)
      else
        throw({:error, :message, message})
      end

    """
    #{base_name}:#{line}:#{warning_name}
    #{string}
    """
  end

  defp show_count_skipped(warnings, filtered_warnings) do
    warnings_count = Enum.count(warnings)
    filtered_warnings_count = Enum.count(filtered_warnings)
    skipped_count = warnings_count - filtered_warnings_count
    IO.puts("Total errors: #{warnings_count}, Skipped: #{skipped_count}")

    :ok
  end
end
