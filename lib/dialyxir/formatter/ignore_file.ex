defmodule Dialyxir.Formatter.IgnoreFile do
  @moduledoc false

  @behaviour Dialyxir.Formatter

  @impl Dialyxir.Formatter
  def format({_tag, {file, _location}, {warning_name, _arguments}}) do
    ~s({"#{file}", :#{warning_name}},)
  end
end
