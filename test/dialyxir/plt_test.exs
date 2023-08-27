defmodule Dialyxir.PltTest do
  alias Dialyxir.Plt
  import ExUnit.CaptureIO, only: [capture_io: 1]

  use ExUnit.Case

  def absname_plt(plt, _, _, _), do: IO.puts(Path.absname(plt))

  test "check plts" do
    plts = [
      {"/var/dialyxir_erlang-20.3.plt", [:erts, :kernel, :stdlib, :crypto]},
      {"/var/dialyxir_erlang-20.3_elixir-1.6.2_deps-dev.plt", [:elixir]}
    ]

    fun = fn ->
      assert Plt.check(plts, &absname_plt/4) == :ok
    end

    assert capture_io(fun) =~
             "Looking up modules in dialyxir_erlang-20.3.plt\n" <>
               "Looking up modules in dialyxir_erlang-20.3_elixir-1.6.2_deps-dev.plt\n" <>
               "/var/dialyxir_erlang-20.3_elixir-1.6.2_deps-dev.plt\n" <>
               "/var/dialyxir_erlang-20.3.plt\n"
  end
end
