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
  end

  def get_tool(id) do
    Repo.get(Tool, id)
  end

  def get_tool!(id) do
    Repo.get!(Tool, id)
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
end
