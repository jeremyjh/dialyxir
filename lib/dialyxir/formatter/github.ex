defmodule Dialyxir.Formatter.Github do
  @moduledoc false

  @behaviour Dialyxir.Formatter

  @impl Dialyxir.Formatter
  def format({_tag, {file, line}, {warning_name, arguments}}) do
    base_name = Path.relative_to_cwd(file)

    warning = warning(warning_name)
    string = warning.format_short(arguments)

    "::warning file=#{base_name},line=#{line},title=#{warning_name}::#{string}"
  end

  defp warning(warning_name) do
    warnings = Dialyxir.Warnings.warnings()

    if Map.has_key?(warnings, warning_name) do
      Map.get(warnings, warning_name)
    else
      throw({:error, :unknown_warning, warning_name})
    end
  end
end
