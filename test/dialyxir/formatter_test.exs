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
        remaining = Formatter.format_and_filter([warning], Project, [], :short)
        assert remaining == []
      end)
    end

    test "does not filter lines not matching the pattern" do
      warning =
        {:warn_return_no_exit, {'a/different_file.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}}

      in_project(:ignore, fn ->
        [remaining] = Formatter.format_and_filter([warning], Project, [], :short)
        assert remaining =~ ~r/different_file.* no local return/
      end)
    end

    test "can filter by regex" do
      warning =
        {:warn_return_no_exit, {'a/regex_file.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}}

      in_project(:ignore, fn ->
        remaining = Formatter.format_and_filter([warning], Project, [], :short)
        assert remaining == []
      end)
    end

    test "lists unnecessary skips" do
      warning =
        {:warn_return_no_exit, {'a/regex_file.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}}

      in_project(:ignore, fn ->
        assert {:warn, [], {:unused_filters_present, warning}} =
                 Formatter.format_and_filter([warning], Project, [], :dialyxir)

        assert warning =~ "Unused filters:"
      end)
    end

    test "error on unnecessary skips with halt_exit_status" do
      warning =
        {:warn_return_no_exit, {'a/regex_file.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}}

      filter_args = [{:halt_exit_status, true}]

      in_project(:ignore, fn ->
        {:error, [], {:unused_filters_present, error}} =
          Formatter.format_and_filter([warning], Project, filter_args, :dialyxir)

        assert error =~ "Unused filters:"
      end)
    end

    test "overwrite ':list_unused_filters_present'" do
      warning =
        {:warn_return_no_exit, {'a/regex_file.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}}

      filter_args = [{:list_unused_filters, false}]

      in_project(:ignore, fn ->
        assert {:warn, [], {:unused_filters_present, warning}} =
                 Formatter.format_and_filter([warning], Project, filter_args, :dialyxir)

        refute warning =~ "Unused filters:"
      end)
    end
  end
end
