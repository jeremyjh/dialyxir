defmodule Dialyxir.Output do
  alias IO.ANSI

  def color(text, color) when is_binary(text) do
    if ANSI.enabled? do
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
end
