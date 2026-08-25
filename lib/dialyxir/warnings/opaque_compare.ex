defmodule Dialyxir.Warnings.OpaqueCompare do
  @moduledoc """
  Attempt to test for equality or inequality between a term and an
  opaque type.

  This warning replaces the separate `:opaque_eq` and `:opaque_neq`
  warnings starting in OTP 28.

  ## Example

      defmodule OpaqueStruct do
        defstruct [:opaque]

        @opaque t :: %OpaqueStruct{}
      end

      defmodule Example do
        @spec bad_compare(OpaqueStruct.t()) :: boolean()
        def bad_compare(opaque) do
          opaque == %OpaqueStruct{}
        end
      end
  """

  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :opaque_compare
  def warning(), do: :opaque_compare

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short([_type, op, opaque_type]) do
    pretty_opaque_type = Erlex.pretty_print_type(opaque_type)
    kind = op_to_kind(op)

    "Attempt to test for #{kind} with an opaque type #{pretty_opaque_type}."
  end

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([type, op, opaque_type]) do
    pretty_type = Erlex.pretty_print_type(type)
    pretty_opaque_type = Erlex.pretty_print_type(opaque_type)
    kind = op_to_kind(op)

    "Attempt to test for #{kind} between a term of type #{pretty_type}" <>
      " and a term of opaque type #{pretty_opaque_type}."
  end

  defp op_to_kind(op) do
    op_string = to_string(op)

    if op_string in ["=:=", "=="] do
      "equality"
    else
      "inequality"
    end
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    @moduledoc
  end
end
