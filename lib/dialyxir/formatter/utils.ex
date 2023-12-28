defmodule Dialyxir.Formatter.Utils do
  def warning(warning_name) do
    warnings = Dialyxir.Warnings.warnings()

    if Map.has_key?(warnings, warning_name) do
      Map.get(warnings, warning_name)
    else
      throw({:error, :unknown_warning, warning_name})
    end
  end

  @doc false
  @spec format_location(:erl_anno.location()) :: String.t()
  def format_location(location)
  def format_location({line, column}), do: "#{line}:#{column}"
  def format_location(line), do: "#{line}"
end
