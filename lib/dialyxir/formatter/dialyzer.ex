defmodule Dialyxir.Formatter.Dialyzer do
  @moduledoc false

  @behaviour Dialyxir.Formatter

  @impl Dialyxir.Formatter
  def format(warning) do
    # OTP 22 uses indented output, but that's incompatible with dialyzer.ignore-warnings format.
    # Can be disabled, but OTP 21 and older only accept an atom, so only disable on OTP 22+.
    opts =
      if String.to_integer(System.otp_release()) < 22,
        do: :fullpath,
        else: [{:filename_opt, :fullpath}, {:indent_opt, false}]

    warning
    |> :dialyzer.format_warning(opts)
    |> String.Chars.to_string()
    |> String.replace_trailing("\n", "")
  end
end
