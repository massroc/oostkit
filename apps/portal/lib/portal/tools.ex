defmodule Portal.Tools do
  @moduledoc """
  Context for managing platform tools.
  """
  import Ecto.Query
  alias Portal.Repo
  alias Portal.Tools.Tool

  @categories_ordered ~w(learning workshop_management team_workshops)

  def list_tools do
    Tool
    |> order_by([:category, :sort_order])
    |> Repo.all()
    |> Enum.map(&apply_config_overrides/1)
  end

  def list_tools_grouped do
    list_tools()
    |> Enum.group_by(& &1.category)
    |> Map.new(fn {category, tools} ->
      {category, Enum.sort_by(tools, &status_sort_key/1)}
    end)
  end

  defp status_sort_key(tool) do
    if Tool.effective_status(tool) == :live, do: 0, else: 1
  end

  def categories_ordered, do: @categories_ordered

  def category_label("learning"), do: "Learning"
  def category_label("workshop_management"), do: "Workshop Management"
  def category_label("team_workshops"), do: "Team Workshops"

  def get_tool(id) do
    case Repo.get(Tool, id) do
      nil -> nil
      tool -> apply_config_overrides(tool)
    end
  end

  def get_tool!(id) do
    Tool |> Repo.get!(id) |> apply_config_overrides()
  end

  def create_tool(attrs) do
    %Tool{}
    |> Tool.changeset(attrs)
    |> Repo.insert()
  end

  def update_tool(%Tool{} = tool, attrs) do
    tool
    |> Tool.changeset(attrs)
    |> Repo.update()
  end

  def upsert_tool(attrs) do
    %Tool{}
    |> Tool.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: :id
    )
  end

  def toggle_admin_enabled(%Tool{} = tool) do
    update_tool(tool, %{admin_enabled: !tool.admin_enabled})
  end

  defp apply_config_overrides(%Tool{id: id} = tool) do
    tool =
      case Application.get_env(:portal, :tool_urls, %{}) do
        urls when is_map(urls) -> %{tool | url: Map.get(urls, id, tool.url)}
        _ -> tool
      end

    case Application.get_env(:portal, :tool_status_overrides, %{}) do
      overrides when is_map(overrides) ->
        case Map.get(overrides, id) do
          nil -> tool
          status -> %{tool | default_status: status}
        end

      _ ->
        tool
    end
  end
end
