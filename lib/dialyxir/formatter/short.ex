defmodule Dialyxir.Formatter.Short do
  @moduledoc false

  alias Dialyxir.Formatter.Utils

  @behaviour Dialyxir.Formatter

  @impl Dialyxir.Formatter
  def format({_tag, {file, location}, {warning_name, arguments}}) do
    base_name = Path.relative_to_cwd(file)

    warning = Utils.warning(warning_name)
    string = warning.format_short(arguments)

    "#{base_name}:#{Utils.format_location(location)}:#{warning_name} #{string}"
  end
end
