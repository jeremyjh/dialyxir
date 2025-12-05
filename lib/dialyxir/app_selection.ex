defmodule Dialyxir.AppSelection do
  @moduledoc """
  Centralizes resolution of `apps` and `warning_apps` for Dialyxir.

  Responsibilities:
  - Merge CLI-provided lists with mix.exs config, honoring CLI precedence.
  - Expand `:transitive`/`:project` flags via `Dialyxir.Project` helpers.
  - Normalize atoms/strings/charlists to atoms.
  - Filter non-project entries from `warning_apps` (incremental mode only) and warn about removals.
  - Merge `warning_apps` into `apps` so Dialyzer analyzes everything it needs while only emitting warnings for `warning_apps`.
  """
  import Dialyxir.Output
  alias Dialyxir.Project

  @type t :: %{
          apps: [atom()],
          warning_apps: [atom()]
        }

  @doc """
  Resolve effective `apps` and `warning_apps` given CLI lists, config values, and incremental mode.

  Expected options:
  - `:incremental` (boolean) – enables app-mode; when false, returns empty lists.
  - `:cli_apps`, `:cli_warning_apps` – lists parsed from CLI (empty when not provided).
  - `:config_apps`, `:config_warning_apps` – values from mix.exs (may be lists or flags).

  Returns a map `%{apps: [...], warning_apps: [...]}` with `warning_apps` filtered to project apps
  and merged into `apps` when incremental is enabled.

  ## Examples

      iex> Dialyxir.AppSelection.resolve(
      ...>   incremental: true,
      ...>   cli_apps: [:my_dep],
      ...>   cli_warning_apps: [],
      ...>   config_apps: [:transitive],
      ...>   config_warning_apps: [:project]
      ...> )
      %{apps: [:my_dep | _], warning_apps: [:my_app | _]}
  """
  def resolve(opts) do
    incremental? = Keyword.get(opts, :incremental, false)
    cli_apps = Keyword.get(opts, :cli_apps, [])
    cli_warning_apps = Keyword.get(opts, :cli_warning_apps, [])
    config_apps = Keyword.get(opts, :config_apps)
    config_warning_apps = Keyword.get(opts, :config_warning_apps)

    {apps, warning_apps} =
      resolve_apps(incremental?, cli_apps, cli_warning_apps, config_apps, config_warning_apps)

    warning_apps = maybe_filter_warning_apps(warning_apps, incremental?)
    apps = maybe_merge_warning_apps(apps, warning_apps, incremental?)

    %{apps: apps, warning_apps: warning_apps}
  end

  defp resolve_apps(true, cli_apps, cli_warning_apps, config_apps, config_warning_apps) do
    {
      resolve_list(cli_apps, config_apps, :apps),
      resolve_list(cli_warning_apps, config_warning_apps, :warning_apps)
    }
  end

  defp resolve_apps(false, _cli_apps, _cli_warning_apps, _config_apps, _config_warning_apps) do
    {[], []}
  end

  defp resolve_list([], config_value, key), do: normalize(config_value, key)
  defp resolve_list(cli_list, _config_value, key), do: normalize(cli_list, key)

  defp normalize(list, _key) when list == nil, do: []

  defp normalize(list, key) when is_list(list) do
    list
    |> expand_flags(key)
    |> Enum.map(&normalize_app/1)
  end

  defp normalize(:project, _key), do: Project.project_apps()
  defp normalize(:transitive, :apps), do: Project.resolve_apps(apps: :transitive) || []

  defp normalize(:transitive, :warning_apps) do
    Project.resolve_warning_apps(warning_apps: :transitive) || []
  end

  defp normalize(_unknown, _key), do: []

  defp expand_flags(list, key) do
    case :transitive in list do
      true ->
        list
        |> Enum.reject(&(&1 == :transitive))
        |> Kernel.++(resolve_transative_apps(key, :transitive))
        |> Enum.uniq()

      false ->
        list
    end
  end

  defp resolve_transative_apps(key, :transitive) do
    case key do
      :apps -> Project.resolve_apps(apps: :transitive) || []
      :warning_apps -> Project.resolve_warning_apps(warning_apps: :transitive) || []
    end
  end

  defp normalize_app(app) when is_atom(app), do: app
  defp normalize_app(app) when is_binary(app), do: String.to_atom(app)

  defp normalize_app(app) when is_list(app) do
    app |> List.to_string() |> String.to_atom()
  end

  defp maybe_filter_warning_apps(warning_apps, true) do
    {project_warning_apps, filtered_apps} =
      Enum.split_with(warning_apps, &project_app?/1)

    if filtered_apps != [] do
      warning("""
      The following applications in warning_apps were filtered out (only project apps should be in warning_apps):
      #{inspect(filtered_apps)}

      Dependencies and OTP apps should be in 'apps' only, not 'warning_apps'.
      """)
    end

    project_warning_apps
  end

  defp maybe_filter_warning_apps(_warning_apps, false), do: []

  defp project_app?(app) do
    Project.project_apps()
    |> Enum.member?(app)
  end

  defp maybe_merge_warning_apps(apps, warning_apps, true) when warning_apps != [] do
    (apps ++ warning_apps) |> Enum.uniq()
  end

  defp maybe_merge_warning_apps(apps, _warning_apps, _incremental?), do: apps
end
