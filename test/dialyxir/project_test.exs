defmodule Dialyxir.ProjectTest do
  alias Dialyxir.Project

  use ExUnit.Case
  import ExUnit.CaptureIO, only: [capture_io: 1]

  defp in_project(app, f) do
    Mix.Project.in_project(app, "test/fixtures/#{Atom.to_string(app)}", fn _ -> f.() end)
  end

  test "Default Project PLT File in _build dir" do
    in_project :default_apps, fn ->
      assert Regex.match?(~r/_build.*plt/, Project.plt_file())
    end
  end

  test "Can specify a different PLT file name" do
    in_project :local_plt, fn ->
      assert Regex.match?(~r/local\.plt/, Project.plt_file())
    end
  end

  test "Deprecation warning on use of bare :plt_file" do
    in_project :local_plt, fn ->
      out = capture_io(&Project.check_config/0)
      assert Regex.match?(~r/.*plt_path.*deprecated.*/, out)
    end
  end

  test "Can specify a different PLT file name along with :no_warn" do
    in_project :local_plt_no_warn, fn ->
      assert Regex.match?(~r/local\.plt/, Project.plt_file())
    end
  end

  test "No deprecation warning on use of plt_file: {:no_warn, myfile}" do
    in_project :local_plt_no_warn, fn ->
      out = capture_io(&Project.check_config/0)
      refute Regex.match?(~r/.*plt_path.*deprecated.*/, out)
    end
  end

  test "App list for default contains direct and
        indirect :application dependencies" do
    in_project :default_apps, fn ->
      assert Enum.member?(Project.cons_apps, :logger) #direct
      assert Enum.member?(Project.cons_apps, :public_key) #direct
      assert Enum.member?(Project.cons_apps, :asn1) #indirect
    end
  end

  test "App list for :apps_direct contains only direct dependencies" do
    in_project :direct_apps, fn ->
      assert Enum.member?(Project.cons_apps, :logger) #direct
      assert Enum.member?(Project.cons_apps, :public_key) #direct
      refute Enum.member?(Project.cons_apps, :asn1) #indirect
    end
  end

  test "Core PLT files located in mix home by default" do
    in_project :default_apps, fn ->
      assert String.contains?(Project.erlang_plt(), Mix.Utils.mix_home())
    end
  end

  test "Core PLT file paths can be specified with :plt_core_path" do
    in_project :alt_core_path, fn ->
      assert String.contains?(Project.erlang_plt(), "_build")
    end
  end

  test "By default core elixir and erlang plts are in mix.home" do
    in_project :default_apps, fn ->
      assert String.contains?(Project.erlang_plt(), Mix.Utils.mix_home())
    end
  end

end
