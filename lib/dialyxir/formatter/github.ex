defmodule Dialyxir.Formatter.Github do
  @moduledoc false

  @behaviour Dialyxir.Formatter

  @impl Dialyxir.Formatter
  def format({_tag, {file, line}, {warning_name, _arguments}}) do
    base_name = Path.relative_to_cwd(file)

    warning = warning(warning_name)
    string = warning.format_short(arguments)

    "::warning file=#{base_name},line=#{line},title=#{warning_name}::#{string}"
  end
end
