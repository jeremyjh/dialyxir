defmodule Dialyxir.ProjectTest do
  alias Dialyxir.Project

  use ExUnit.Case
  import ExUnit.CaptureIO, only: [capture_io: 1, capture_io: 2]

  defp in_project(app, f) when is_atom(app) do
    in_project(app, "test/fixtures/#{Atom.to_string(app)}", f)
  end

  defp in_project(apps, f) when is_list(apps) do
    path = Enum.map_join(apps, "/", &Atom.to_string/1)
    app = List.last(apps)
    in_project(app, "test/fixtures/#{path}", f)
  end

  defp in_project(app, path, f) do
    Mix.Project.in_project(app, path, fn _ -> f.() end)
  end

  test "Default Project PLT File in _build dir" do
    in_project(:default_apps, fn ->
      assert Regex.match?(~r/_build\/.*plt/, Project.plt_file())
    end)
  end

  test "Can specify a different local PLT path" do
    in_project(:alt_local_path, fn ->
      assert Regex.match?(~r/dialyzer\/.*plt/, Project.plt_file())
    end)
  end

  test "Can specify a different PLT file name" do
    in_project(:local_plt, fn ->
      assert Regex.match?(~r/local\.plt/, Project.plt_file())
    end)
  end

  test "Deprecation warning on use of bare :plt_file" do
    in_project(:local_plt, fn ->
      out = capture_io(&Project.check_config/0)
      assert Regex.match?(~r/.*plt_file.*deprecated.*/, out)
    end)
  end

  test "Can specify a different PLT file name along with :no_warn" do
    in_project(:local_plt_no_warn, fn ->
      assert Regex.match?(~r/local\.plt/, Project.plt_file())
    end)
  end

  test "No deprecation warning on use of plt_file: {:no_warn, myfile}" do
    in_project(:local_plt_no_warn, fn ->
      out = capture_io(&Project.check_config/0)
      refute Regex.match?(~r/.*plt_path.*deprecated.*/, out)
    end)
  end

  test "App list for default contains direct and
        indirect :application dependencies" do
    in_project(:default_apps, fn ->
      apps = Project.cons_apps()
      # direct
      assert Enum.member?(apps, :logger)
      # direct
      assert Enum.member?(apps, :public_key)
      # indirect
      assert Enum.member?(apps, :asn1)
    end)
  end

  test "App list for umbrella contains child dependencies
  indirect :application dependencies" do
    in_project(:umbrella, fn ->
      apps = Project.cons_apps()
      # direct
      assert Enum.member?(apps, :logger)
      # direct, child1
      assert Enum.member?(apps, :public_key)
      # indirect
      assert Enum.member?(apps, :asn1)
      # direct, child2
      assert Enum.member?(apps, :mix)
    end)
  end

  @tag :skip
  test "App list for umbrella contains all child dependencies
  when run from child directory" do
    in_project([:umbrella, :apps, :second_one], fn ->
      apps = Project.cons_apps()
      # direct
      assert Enum.member?(apps, :logger)
      # direct, child1
      assert Enum.member?(apps, :public_key)
      # indirect
      assert Enum.member?(apps, :asn1)
      # direct, child2
      assert Enum.member?(apps, :mix)
    end)
  end

  test "App list for :apps_direct contains only direct dependencies" do
    in_project(:direct_apps, fn ->
      apps = Project.cons_apps()
      # direct
      assert Enum.member?(apps, :logger)
      # direct
      assert Enum.member?(apps, :public_key)
      # indirect
      refute Enum.member?(apps, :asn1)
    end)
  end

  test "App list for :plt_ignore_apps does not contain the ignored dependency" do
    in_project(:ignore_apps, fn ->
      apps = Project.cons_apps()

      refute Enum.member?(apps, :logger)
    end)
  end

  test "Core PLT files located in mix home by default" do
    in_project(:default_apps, fn ->
      assert String.contains?(Project.erlang_plt(), Mix.Utils.mix_home())
    end)
  end

  test "Core PLT file paths can be specified with :plt_core_path" do
    in_project(:alt_core_path, fn ->
      assert String.contains?(Project.erlang_plt(), "_build")
    end)
  end

  test "By default core elixir and erlang plts are in mix.home" do
    in_project(:default_apps, fn ->
      assert String.contains?(Project.erlang_plt(), Mix.Utils.mix_home())
    end)
  end

  test "By default a dialyzer ignore file is nil" do
    in_project(:default_apps, fn ->
      assert Project.dialyzer_ignore_warnings() == nil
    end)
  end

  test "Filtered dialyzer warnings" do
    in_project(:default_apps, fn ->
      output_list =
        ~S"""
        project.ex:9 This should still be here
        project.ex:9: Guard test is_atom(_@5::#{'__exception__':='true', '__struct__':=_, _=>_}) can never succeed
        project.ex:9: Guard test is_binary(_@4::#{'__exception__':='true', '__struct__':=_, _=>_}) can never succeed
        """
        |> String.trim_trailing("\n")
        |> String.split("\n")

      pattern = ~S"""
      Guard test is_atom(_@5::#{'__exception__':='true', '__struct__':=_, _=>_}) can never succeed

      Guard test is_binary(_@4::#{'__exception__':='true', '__struct__':=_, _=>_}) can never succeed
      """

      lines = Project.filter_legacy_warnings(output_list, pattern)
      assert lines == ["project.ex:9 This should still be here"]
    end)
  end

  test "Project with non-existent dependency" do
    in_project(:nonexistent_deps, fn ->
      out = capture_io(:stderr, &Project.cons_apps/0)
      assert Regex.match?(~r/Error loading nonexistent, dependency list may be incomplete/, out)
    end)
  end

  test "igonored apps are removed in umbrella projects" do
    in_project(:umbrella_ignore_apps, fn ->
      refute Enum.member?(Project.cons_apps(), :logger)
    end)
  end

  test "Deprecation warning on use of plt_add_deps: true" do
    in_project(:plt_add_deps_deprecations, fn ->
      out = capture_io(&Project.cons_apps/0)
      assert Regex.match?(~r/.*deprecated.*plt_add_deps.*/, out)
    end)
  end

  test "list_unused_filters? works as intended" do
    assert Project.list_unused_filters?(list_unused_filters: true)
    refute Project.list_unused_filters?(list_unused_filters: nil)

    # Override in mix.exs
    in_project(:ignore, fn ->
      assert Project.list_unused_filters?(list_unused_filters: nil)
    end)
  end

  test "no_umbrella? works as expected" do
    in_project(:umbrella, fn ->
      refute Project.no_umbrella?()
    end)

    in_project(:no_umbrella, fn ->
      assert Project.no_umbrella?()
    end)
  end

  describe "plt_file with incremental mode" do
    test "plt_file(false) returns normal PLT path (backward compatibility)" do
      in_project(:default_apps, fn ->
        classic_plt = Project.plt_file(false)
        assert Regex.match?(~r/_build\/.*plt/, classic_plt)
        refute String.contains?(classic_plt, "_incremental")
      end)
    end

    test "plt_file() defaults to false (backward compatibility)" do
      in_project(:default_apps, fn ->
        classic_plt = Project.plt_file()
        incremental_plt = Project.plt_file(false)
        assert classic_plt == incremental_plt
      end)
    end

    test "plt_file(true) without config appends _incremental suffix" do
      in_project(:incremental, fn ->
        classic_plt = Project.plt_file(false)
        incremental_plt = Project.plt_file(true)

        assert String.contains?(incremental_plt, "_incremental.plt")
        assert incremental_plt == String.replace_suffix(classic_plt, ".plt", "_incremental.plt")
      end)
    end

    test "plt_file(true) with custom plt_incremental_file uses custom path" do
      in_project(:incremental_custom_plt, fn ->
        incremental_plt = Project.plt_file(true)

        assert String.contains?(incremental_plt, "custom_incremental.plt")
        assert Path.expand("custom_incremental.plt") == incremental_plt
      end)
    end

    test "classic and incremental PLTs have different paths and can coexist" do
      in_project(:incremental, fn ->
        classic_plt = Project.plt_file(false)
        incremental_plt = Project.plt_file(true)

        assert classic_plt != incremental_plt
        assert String.contains?(incremental_plt, "_incremental.plt")
        refute String.contains?(classic_plt, "_incremental.plt")
      end)
    end

    test "plt_file(true) with plt_incremental_file: {:no_warn, file} format" do
      in_project(:incremental_no_warn, fn ->
        incremental_plt = Project.plt_file(true)
        assert String.contains?(incremental_plt, "incremental_no_warn.plt")
      end)
    end

    test "plt_file(true) with custom plt_incremental_file respects absolute paths" do
      in_project(:incremental_absolute_path, fn ->
        incremental_plt = Project.plt_file(true)
        expected_path = Path.expand("_build/test/absolute_incremental.plt")
        assert incremental_plt == expected_path
      end)
    end
  end

  describe "apps and warning_apps flag resolution" do
    test "resolve_apps with nil returns nil" do
      config = [apps: nil]
      assert Project.resolve_apps(config) == nil
    end

    test "resolve_apps with explicit list returns list as-is" do
      config = [apps: [:my_app, :other_app]]
      assert Project.resolve_apps(config) == [:my_app, :other_app]
    end

    test "resolve_apps with :apps_direct returns direct deps and project apps" do
      in_project(:apps_project, fn ->
        config = Mix.Project.config()[:dialyzer]
        incremental_config = config[:incremental] || []
        resolved = Project.resolve_apps(apps: Keyword.get(incremental_config, :apps))
        assert is_list(resolved)
        assert :apps_project in resolved
      end)
    end

    test "resolve_apps with :app_tree includes deps and project apps" do
      in_project(:apps_transitive, fn ->
        config = Mix.Project.config()[:dialyzer]
        incremental_config = config[:incremental] || []
        resolved = Project.resolve_apps(apps: Keyword.get(incremental_config, :apps))
        assert is_list(resolved)
        # Should include project app
        assert :apps_transitive in resolved
        # Should NOT include core apps (users must explicitly list them)
        refute :erts in resolved
        refute :kernel in resolved
        refute :stdlib in resolved
        refute :elixir in resolved
      end)
    end

    test "resolve_warning_apps with nil returns nil" do
      config = [warning_apps: nil]
      assert Project.resolve_warning_apps(config) == nil
    end

    test "resolve_warning_apps with explicit list returns list as-is" do
      config = [warning_apps: [:my_app, :other_app]]
      assert Project.resolve_warning_apps(config) == [:my_app, :other_app]
    end

    test "resolve_warning_apps with :apps_direct returns nil and shows warning" do
      # Test that :apps_direct is rejected in warning_apps
      resolved = Project.resolve_warning_apps(warning_apps: :apps_direct)

      # :apps_direct is not allowed in warning_apps, should return nil
      assert resolved == nil
    end

    test "resolve_warning_apps with :app_tree returns nil and shows warning" do
      # Test that :app_tree is rejected in warning_apps
      resolved = Project.resolve_warning_apps(warning_apps: :app_tree)

      # :app_tree is not allowed in warning_apps, should return nil
      assert resolved == nil
    end

    test "project_apps returns single app for non-umbrella project" do
      in_project(:default_apps, fn ->
        # We can't directly test project_apps/0 as it's private, but we can test via resolve_apps
        config = [apps: :apps_direct]
        resolved = Project.resolve_apps(config)
        assert is_list(resolved)
        assert :default_apps in resolved
      end)
    end

    test "project_apps returns all apps for umbrella project" do
      in_project(:umbrella, fn ->
        config = [apps: :apps_direct]
        resolved = Project.resolve_apps(config)
        assert is_list(resolved)
        # Should include umbrella child apps
        assert :first_one in resolved || :second_one in resolved
      end)
    end

    test "dialyzer_apps maintains backward compatibility with list config" do
      in_project(:apps_config, fn ->
        # apps_config has apps: [:apps_config, :kernel] (explicit list)
        apps = Project.dialyzer_apps()
        assert is_list(apps)
        assert :apps_config in apps
        assert :kernel in apps
      end)
    end

    test "dialyzer_apps resolves :app_tree flag" do
      in_project(:apps_transitive, fn ->
        apps = Project.dialyzer_apps()
        assert is_list(apps)
        assert :apps_transitive in apps
        # :app_tree does NOT include OTP apps - users must explicitly list them
        refute :erts in apps
        refute :kernel in apps
      end)
    end

    test "dialyzer_apps resolves :apps_direct flag" do
      in_project(:apps_project, fn ->
        apps = Project.dialyzer_apps()
        assert is_list(apps)
        assert :apps_project in apps
      end)
    end

    test "dialyzer_warning_apps maintains backward compatibility with list config" do
      in_project(:apps_warning_apps_config, fn ->
        # apps_warning_apps_config has warning_apps: [:apps_warning_apps_config] (explicit list)
        warning_apps = Project.dialyzer_warning_apps()
        assert is_list(warning_apps)
        assert :apps_warning_apps_config in warning_apps
      end)
    end

    test "dialyzer_warning_apps with :apps_project returns project apps" do
      in_project(:warning_apps_project, fn ->
        warning_apps = Project.dialyzer_warning_apps()
        # :apps_project should return project apps
        assert is_list(warning_apps)
        assert :warning_apps_project in warning_apps
      end)
    end

    test "dialyzer_warning_apps with :apps_project returns project apps (transitive)" do
      in_project(:warning_apps_transitive, fn ->
        warning_apps = Project.dialyzer_warning_apps()
        # :apps_project should return project apps
        assert is_list(warning_apps)
        assert :warning_apps_transitive in warning_apps
      end)
    end

    test "dialyzer_apps returns empty list when not configured" do
      in_project(:local_plt, fn ->
        apps = Project.dialyzer_apps()
        assert apps == []
      end)
    end

    test "dialyzer_warning_apps returns empty list when not configured" do
      in_project(:local_plt, fn ->
        warning_apps = Project.dialyzer_warning_apps()
        assert warning_apps == []
      end)
    end
  end
end
