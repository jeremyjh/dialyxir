defmodule Dialyxir.OutputTest do
  alias Dialyxir.Output
  use ExUnit.Case

  describe "format/1" do
    test "Coloring single line warnings" do
      input = "lib/foo.ex:20: Function foo/0 has no local return"
      assert "\e[31mlib/foo.ex:20: Function foo/0 has no local return\e[0m" = Output.format(input)
    end

    test "Coloring multi line warnings" do
      input = "lib/foo.ex:20: Function foo/0 has no local return\ndone in 0m1.56s"
      assert "\e[31mlib/foo.ex:20: Function foo/0 has no local return\e[0m\ndone in 0m1.56s" = Output.format(input)
    end

    test "Coloring a successful 'done' message" do
      input = "done (passed successfully)"
      assert "\e[32mdone (passed successfully)\e[0m" = Output.format(input)
    end

    test "Coloring a 'done' message with warnings" do
      input = "done (warnings were emitted)"
      assert "\e[33mdone (warnings were emitted)\e[0m" = Output.format(input)
    end
  end
end
