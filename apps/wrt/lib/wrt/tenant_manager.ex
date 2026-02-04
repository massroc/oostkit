defmodule Wrt.TenantManager do
  @moduledoc """
  Manages tenant (organisation) schemas for multi-tenancy.

  Uses Triplex for PostgreSQL schema-based multi-tenancy.
  Each organisation gets its own schema with isolated data.
  """

  alias Wrt.Repo

  @doc """
  Creates a new tenant schema for an organisation.

  Returns {:ok, schema_name} on success, {:error, reason} on failure.
  """
  def create_tenant(org_id) when is_integer(org_id) do
    schema_name = tenant_schema_name(org_id)

    with :ok <- Triplex.create(schema_name, Repo),
         {:ok, _} <- migrate_tenant(schema_name) do
      {:ok, schema_name}
    end
  end

  @doc """
  Drops a tenant schema.

  WARNING: This permanently deletes all data for the organisation.
  """
  def drop_tenant(org_id) when is_integer(org_id) do
    schema_name = tenant_schema_name(org_id)
    Triplex.drop(schema_name, Repo)
  end

  @doc """
  Checks if a tenant schema exists.
  """
  def tenant_exists?(org_id) when is_integer(org_id) do
    schema_name = tenant_schema_name(org_id)
    Triplex.exists?(schema_name, Repo)
  end

  @doc """
  Runs migrations for a specific tenant schema.
  """
  def migrate_tenant(schema_name) when is_binary(schema_name) do
    Triplex.migrate(schema_name, Repo)
  end

  @doc """
  Runs migrations for all existing tenant schemas.
  """
  def migrate_all_tenants do
    Triplex.all(Repo)
    |> Enum.filter(&String.starts_with?(&1, "tenant_"))
    |> Enum.each(&migrate_tenant/1)
  end

  @doc """
  Returns the schema name for an organisation.
  """
  def tenant_schema_name(org_id) when is_integer(org_id) do
    "tenant_#{org_id}"
  end

  @doc """
  Extracts the org_id from a tenant schema name.
  """
  def org_id_from_schema(schema_name) when is_binary(schema_name) do
    case String.split(schema_name, "_") do
      ["tenant", id_str] ->
        case Integer.parse(id_str) do
          {id, ""} -> {:ok, id}
          _ -> {:error, :invalid_schema_name}
        end

      _ ->
        {:error, :invalid_schema_name}
    end
  end

  @doc """
  Lists all tenant schemas.
  """
  def list_tenants do
    Triplex.all(Repo)
    |> Enum.filter(&String.starts_with?(&1, "tenant_"))
  end
end
