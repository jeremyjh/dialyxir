defmodule Dialyxir.Warning do

  @callback warning() :: atom
  @callback format_long(any) :: String.t()
end
