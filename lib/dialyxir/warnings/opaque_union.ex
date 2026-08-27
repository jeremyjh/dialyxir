defmodule Dialyxir.Warnings.OpaqueUnion do
  @moduledoc """
  A function body yields a type whose opacity is broken by
  other clauses, or vice versa.

  This is a new warning type introduced in OTP 28 as part of
  the nominal types (EEP-69) rework of opaque type checking.

  ## Example

      defmodule OpaqueStruct do
        defstruct [:opaque]

        @opaque t :: %OpaqueStruct{}
      end

      defmodule Example do
        @spec bad_union(boolean()) :: OpaqueStruct.t()
        def bad_union(true), do: %OpaqueStruct{}
        def bad_union(false), do: OpaqueStruct.new()
      end
  """

  @behaviour Dialyxir.Warning

  @impl Dialyxir.Warning
  @spec warning() :: :opaque_union
  def warning(), do: :opaque_union

  @impl Dialyxir.Warning
  @spec format_short([String.t()]) :: String.t()
  def format_short(args), do: format_long(args)

  @impl Dialyxir.Warning
  @spec format_long([String.t()]) :: String.t()
  def format_long([is_opaque, type]) do
    pretty_type = Erlex.pretty_print_type(type)

    if is_opaque do
      "Body yields the opaque type #{pretty_type} whose opacity is " <>
        "broken by the other clauses."
    else
      "Body yields the type #{pretty_type} which violates the " <>
        "opacity of the other clauses."
    end
  end

  @impl Dialyxir.Warning
  @spec explain() :: String.t()
  def explain() do
    @moduledoc
  end
end
