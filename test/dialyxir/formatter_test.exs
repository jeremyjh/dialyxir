defmodule Dialyxir.FormatterTest do
  use ExUnit.Case
  alias Dialyxir.Formatter
  alias Dialyxir.Project

  defp in_project(app, f) when is_atom(app) do
    Mix.Project.in_project(app, "test/fixtures/#{Atom.to_string(app)}", fn _ -> f.() end)
  end

  describe "exs ignore" do
    test "evaluates an ignore file and ignores warnings matching the pattern" do
      warning =
        {:warn_return_no_exit, {'a/file.ex', 17}, {:no_return, [:only_normal, :format_long, 1]}}

      in_project(:ignore, fn ->
        remaining = Formatter.format_and_filter([warning], Project, :short)
        assert remaining == []
      end)
    end

    test "does not filter lines not matching the pattern" do
      warning =
        {:warn_return_no_exit, {'a/different_file.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}}

      in_project(:ignore, fn ->
        [remaining] = Formatter.format_and_filter([warning], Project, :short)
        assert remaining =~ ~r/different_file.* no local return/
      end)
    end
  end
end
