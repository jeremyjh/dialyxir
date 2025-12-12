defmodule Dialyxir.AppSelectionTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Dialyxir.AppSelection
  alias Dialyxir.Project

  defp in_project(app, fun) when is_atom(app) do
    Mix.Project.in_project(app, "test/fixtures/#{Atom.to_string(app)}", fn _ -> fun.() end)
  end

  test "returns empty lists when incremental is false" do
    selection =
      AppSelection.resolve(
        incremental: false,
        cli_apps: [:cli],
        cli_warning_apps: [:cli_warn],
        config_apps: [:config],
        config_warning_apps: [:config_warn]
      )

    assert selection.apps == []
    assert selection.warning_apps == []
  end

  test "CLI apps override config apps, config warning_apps still used" do
    in_project(:apps_warning_apps_config, fn ->
      selection =
        AppSelection.resolve(
          incremental: true,
          cli_apps: [:cli_app],
          cli_warning_apps: [],
          config_apps: Project.dialyzer_apps(),
          config_warning_apps: Project.dialyzer_warning_apps()
        )

      assert Enum.sort(selection.apps) == Enum.sort([:cli_app, :apps_warning_apps_config])
      assert selection.warning_apps == [:apps_warning_apps_config]
    end)
  end

  test "filters non-project warning_apps and warns" do
    in_project(:local_plt, fn ->
      output =
        capture_io(fn ->
          selection =
            AppSelection.resolve(
              incremental: true,
              cli_apps: [],
              cli_warning_apps: [:local_plt, :logger],
              config_apps: Project.dialyzer_apps(),
              config_warning_apps: Project.dialyzer_warning_apps()
            )

          assert selection.warning_apps == [:local_plt]
        end)

      assert output =~ "filtered out"
    end)
  end

  test "merges warning_apps into apps" do
    in_project(:apps_warning_apps_config, fn ->
      selection =
        AppSelection.resolve(
          incremental: true,
          cli_apps: [:kernel],
          cli_warning_apps: [:apps_warning_apps_config],
          config_apps: Project.dialyzer_apps(),
          config_warning_apps: Project.dialyzer_warning_apps()
        )

      assert :kernel in selection.apps
      assert :apps_warning_apps_config in selection.apps
    end)
  end

  test "apps list keeps project app named :apps_project" do
    in_project(:apps_project, fn ->
      selection =
        AppSelection.resolve(
          incremental: true,
          cli_apps: [],
          cli_warning_apps: [],
          config_apps: Project.dialyzer_apps(),
          config_warning_apps: Project.dialyzer_warning_apps()
        )

      assert selection.apps == [:apps_project]
    end)
  end
end
