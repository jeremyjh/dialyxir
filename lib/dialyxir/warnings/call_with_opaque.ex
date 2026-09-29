defmodule Dialyxir.Warnings.CallWithOpaque do
  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :call_with_opaque
  def warning(), do: :call_with_opaque

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short([_module, function | _]) do
    "Type mismatch in call with opaque term in #{function}."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([module, function, args, conflicts, expected_args]) do
    pretty_module = Erlex.pretty_print(module)
    arg_positions = Enum.map(conflicts, &position/1)

    "The call #{pretty_module}.#{function}#{args} contains #{form_positions(arg_positions)} " <>
      "when #{form_expected(expected_args)}."
  end

  # OTP 28+ passes {position, type, type_string} triples; earlier releases pass positions.
  defp position({position, _type, _type_string}), do: position
  defp position(position) when is_integer(position), do: position

  defp form_positions(arg_positions = [_]) do
    form_position_string = Dialyxir.WarningHelpers.form_position_string(arg_positions)
    "an opaque term in #{form_position_string} argument"
  end

  defp form_positions(arg_positions) do
    form_position_string = Dialyxir.WarningHelpers.form_position_string(arg_positions)
    "opaque terms in #{form_position_string} arguments"
  end

  defp form_expected([type]) do
    type_string = :erl_types.t_to_string(type)

    if :erl_types.t_is_opaque(type) do
      "an opaque term of type #{type_string} is expected"
    else
      "a structured term of type #{type_string} is expected"
    end
  end

  defp form_expected(_expected_args) do
    "terms of different types are expected in these positions"
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    Dialyxir.Warning.default_explain()
  end
end
