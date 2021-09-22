defmodule Dialyxir.FormatterTest do
  use ExUnit.Case

  import ExUnit.CaptureIO, only: [capture_io: 1]

  alias Dialyxir.Formatter
  alias Dialyxir.Project

  defp in_project(app, f) when is_atom(app) do
    Mix.Project.in_project(app, "test/fixtures/#{Atom.to_string(app)}", fn _ -> f.() end)
  end

  describe "exs ignore" do
    test "evaluates an ignore file and ignores warnings matching the pattern" do
      warnings = [
        {:warn_return_no_exit, {'lib/short_description.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}},
        {:warn_return_no_exit, {'lib/file/warning_type.ex', 18},
         {:no_return, [:only_normal, :format_long, 1]}},
        {:warn_return_no_exit, {'lib/file/warning_type/line.ex', 19},
         {:no_return, [:only_normal, :format_long, 1]}}
      ]

      in_project(:ignore, fn ->
        {:error, remaining, _unused_filters_present} =
          Formatter.format_and_filter(warnings, Project, [], :short)

        assert remaining == []
      end)
    end

    test "does not filter lines not matching the pattern" do
      warning =
        {:warn_return_no_exit, {'a/different_file.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}}

      in_project(:ignore, fn ->
        {:error, [remaining], _} = Formatter.format_and_filter([warning], Project, [], :short)
        assert remaining =~ ~r/different_file.* no local return/
      end)
    end

    test "can filter by regex" do
      warning =
        {:warn_return_no_exit, {'a/regex_file.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}}

      in_project(:ignore, fn ->
        {:error, remaining, _unused_filters_present} =
          Formatter.format_and_filter([warning], Project, [], :short)

        assert remaining == []
      end)
    end

    test "lists unnecessary skips as warnings if ignoring exit status " do
      warning =
        {:warn_return_no_exit, {'a/regex_file.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}}

      filter_args = [{:ignore_exit_status, true}]

      in_project(:ignore, fn ->
        assert {:warn, [], {:unused_filters_present, warning}} =
                 Formatter.format_and_filter([warning], Project, filter_args, :dialyxir)

        assert warning =~ "Unused filters:"
      end)
    end

    test "error on unnecessary skips without ignore_exit_status" do
      warning =
        {:warn_return_no_exit, {'a/regex_file.ex', 17},
         {:no_return, [:only_normal, :format_long, 1]}}

      filter_args = [{:ignore_exit_status, false}]

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

  describe "simple string ignore" do
    test "evaluates an ignore file and ignores warnings matching the pattern" do
      warning =
        {:warn_matching, {'a/file.ex', 17}, {:pattern_match, ['pattern \'ok\'', '\'error\'']}}

      in_project(:ignore_string, fn ->
        assert Formatter.format_and_filter([warning], Project, [], :dialyzer) ==
                 {:ok, [], :no_unused_filters}
      end)
    end
  end

  test "listing unused filter behaves the same for different formats" do
    warnings = [
      {:warn_return_no_exit, {'a/regex_file.ex', 17},
       {:no_return, [:only_normal, :format_long, 1]}},
      {:warn_return_no_exit, {'a/another-file.ex', 18}, {:unknown_type, {:M, :F, :A}}}
    ]

    expected_warning = "a/another-file.ex:18"

    expected_unused_filter = ~s(Unused filters:
{"lib/short_description.ex:17:no_return Function format_long/1 has no local return."}
{"lib/file/warning_type.ex", :no_return, 18}
{"lib/file/warning_type/line.ex", :no_return, 19})

    filter_args = [{:list_unused_filters, true}]

    for format <- [:short, :dialyxir, :dialyzer] do
      in_project(:ignore, fn ->
        capture_io(fn ->
          result = Formatter.format_and_filter(warnings, Project, filter_args, format)

          assert {:error, [warning], {:unused_filters_present, unused}} = result
          assert warning =~ expected_warning
          assert unused == expected_unused_filter
          # A warning for regex_file.ex was explicitly put into format_and_filter.
          refute unused =~ "regex_file.ex"
        end)
      end)
    end
  end
end
