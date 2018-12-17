defmodule Dialyxir.Output do
  alias IO.ANSI

  def color(text, color) when is_binary(text) do
    if ANSI.enabled?() do
      case color do
        :red ->
          ANSI.red() <> text <> ANSI.reset()

        :yellow ->
          ANSI.yellow() <> text <> ANSI.reset()

        :green ->
          ANSI.green() <> text <> ANSI.reset()

        _ ->
          text
      end
    else
      text
    end
  end

  def info(""), do: :ok
  def info(text), do: Mix.shell().info(text)

  def error(""), do: :ok
  def error(text), do: Mix.shell().error(text)
end
