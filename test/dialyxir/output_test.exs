defmodule Dialyxir.OutputTest do
  use ExUnit.Case
  alias Dialyxir.Output

  setup do
    ansi_enabled = IO.ANSI.enabled?()

    on_exit(fn ->
      Application.put_env(:elixir, :ansi_enabled, ansi_enabled)
    end)
  end

  describe "color/2" do
    test "inserts ANSI escape codes when they are enabled" do
      Application.put_env(:elixir, :ansi_enabled, true)

      assert Output.color("hello", :red) == [[[[] | "\e[31m"], "hello"] | "\e[0m"]
    end

    test "does not insert escape codes when they are disabled" do
      Application.put_env(:elixir, :ansi_enabled, false)

      assert Output.color("world", :green) == [[], "world"]
    end
  end
end
