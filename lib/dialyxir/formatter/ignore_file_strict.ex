defmodule Dialyxir.Formatter.IgnoreFileStrict do
  @moduledoc false

  alias Dialyxir.Formatter.Utils

  @behaviour Dialyxir.Formatter

  @impl Dialyxir.Formatter
  def format({_tag, {file, _location}, {warning_name, arguments}}) do
    warning = Utils.warning(warning_name)
    string = warning.format_short(arguments)

    ~s({"#{file}", "#{string}"},)
  end
end
