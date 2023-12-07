defmodule Dialyxir.Formatter.Dialyxir do
  @moduledoc false

  alias Dialyxir.Formatter.Utils

  @behaviour Dialyxir.Formatter

  @impl Dialyxir.Formatter
  def format(dialyzer_warning = {_tag, {file, location}, message}) do
    {warning_name, arguments} = message
    base_name = Path.relative_to_cwd(file)

    formatted =
      try do
        warning = Utils.warning(warning_name)
        string = warning.format_long(arguments)

        """
        #{base_name}:#{Utils.format_location(location)}:#{warning_name}
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

    formatted <> String.duplicate("_", 80)
  end

  defp wrap_error_message(message, warning) do
    """
    Please file a bug in https://github.com/jeremyjh/dialyxir/issues with this message.

    #{message}

    Legacy warning:
    #{Dialyxir.Formatter.Dialyzer.format(warning)}
    """
  end
end
