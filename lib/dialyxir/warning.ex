defmodule Dialyxir.Warning do
  @moduledoc """
  Behaviour for defining warning semantings.

  Contains callbacks for various warnings
  """

  @doc """
  By expressiing the warning that is to be matched on, error handlong
  and dispatching can be avoided in format functions.
  """
  @callback warning() :: atom

  @doc """
  The default documentation when seeing an error wihout the user
  otherwise overriding the format.
  """
  @callback format_long([String.t()] | {String.t(), String.t(), String.t()} | String.t()) ::
              String.t()

  @doc """
  A short message, often missing things like success types and expected types for space.
  """
  @callback format_short([String.t()] | {String.t(), String.t(), String.t()} | String.t()) ::
              String.t()

  @doc """
  Explanation for a warning of this type. Should include a simple example of how to trigger it.
  """
  @callback explain() :: String.t()
end
