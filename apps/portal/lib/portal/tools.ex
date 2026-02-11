defmodule Portal.Tools do
  @moduledoc """
  Context for managing platform tools.
  """
  import Ecto.Query
  alias Portal.Repo
  alias Portal.Tools.Tool

  def list_tools do
    Tool
    |> order_by(:sort_order)
    |> Repo.all()
    |> Enum.map(&apply_config_url/1)
  end

  def get_tool(id) do
    case Repo.get(Tool, id) do
      nil -> nil
      tool -> apply_config_url(tool)
    end
  end

  def get_tool!(id) do
    Tool |> Repo.get!(id) |> apply_config_url()
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

  defp apply_config_url(%Tool{id: id} = tool) do
    case Application.get_env(:portal, :tool_urls, %{}) do
      urls when is_map(urls) -> %{tool | url: Map.get(urls, id, tool.url)}
      _ -> tool
    end
  end
end
