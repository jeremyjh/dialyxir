defmodule Dialyxir.Dialyzer do
  import Dialyxir.Output, only: [color: 2]
  alias String.Chars
  alias Dialyxir.Project

  defmodule Runner do
    def run(args, filterer) do
      try do
        {duration_ms, result} = :timer.tc(&:dialyzer.run/1, [args])
        { :ok, { formatted_time(duration_ms), format_and_filter(result, filterer) } }
      catch
        {:dialyzer_error, msg} ->
          { :error, ":dialyzer.run error: " <> Chars.to_string(msg) }
      end
    end

    defp format_and_filter(warnings, filterer) do
      warnings
        |> Enum.map(&format_warning(&1))
        |> filterer.filter_warnings()
    end

    defp format_warning(warning) do
      :dialyzer.format_warning(warning, :fullpath)
      |> Chars.to_string
      |> String.replace_trailing("\n", "")
    end

    defp formatted_time(duration_ms) do
      minutes = div(duration_ms, 6_000_000)
      seconds = rem(duration_ms, 6_000_000) / 1_000_000 |> Float.round(2)
      "done in #{minutes}m#{seconds}s"
    end
  end

  @success_msg color("done (passed successfully)", :green)
  @warnings_msg color("done (warnings were emitted)", :yellow)
  @success_return_code 0
  @warning_return_code 2
  @error_return_code 1

  def dialyze(args, runner \\ Runner, filterer \\ Project) do
    case runner.run(args, filterer) do
      { :ok, { time, [] } } ->
        { :ok, @success_return_code,  [ time, @success_msg ] }
      { :ok, { time, result } } ->
        warnings = Enum.map(result, &color(&1, :red))
        { :warn, @warning_return_code, [ time ] ++ warnings ++ [ @warnings_msg ] }
      { :error, msg } ->
        { :error, @error_return_code, [ color(msg, :red) ] }
    end
  end
end
