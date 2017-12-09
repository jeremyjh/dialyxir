defmodule Dialyxir.Dialyzer do
  import Dialyxir.Output, only: [color: 2]
  alias String.Chars
  alias Dialyxir.Formatter
  alias Dialyxir.Project

  defmodule Runner do
    def run(args, filterer) do
      try do
        {duration_ms, result} = :timer.tc(&:dialyzer.run/1, [args])
        {:ok, {Formatter.formatted_time(duration_ms), Formatter.format_and_filter(result, filterer)}}
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
