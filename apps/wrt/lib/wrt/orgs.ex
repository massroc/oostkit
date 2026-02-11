defmodule Wrt.Orgs do
  @moduledoc """
  The Orgs context.

  Handles tenant-scoped operations for organisation administration.
  All functions require a tenant prefix to be passed.
  """

  import Ecto.Query, warn: false

  alias Wrt.Orgs.OrgAdmin
  alias Wrt.Repo

  # =============================================================================
  # Org Admin Functions
  # =============================================================================

  @doc """
  Lists all org admins for a tenant.
  """
  def list_org_admins(tenant) do
    OrgAdmin
    |> order_by([a], asc: a.name)
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Gets an org admin by ID.
  """
  def get_org_admin(tenant, id) do
    Repo.get(OrgAdmin, id, prefix: tenant)
  end

  @doc """
  Gets an org admin by ID, raising if not found.
  """
  def get_org_admin!(tenant, id) do
    Repo.get!(OrgAdmin, id, prefix: tenant)
  end

  @doc """
  Gets an org admin by email.
  """
  def get_org_admin_by_email(tenant, email) when is_binary(email) do
    OrgAdmin
    |> where([a], a.email == ^String.downcase(email))
    |> Repo.one(prefix: tenant)
  end

  @doc """
  Creates an org admin.
  """
  def create_org_admin(tenant, attrs) do
    %OrgAdmin{}
    |> OrgAdmin.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Deletes an org admin.
  """
  def delete_org_admin(tenant, %OrgAdmin{} = org_admin) do
    Repo.delete(org_admin, prefix: tenant)
  end

  @doc """
  Authenticates an org admin by email and password.
  """
  def authenticate_org_admin(tenant, email, password) do
    org_admin = get_org_admin_by_email(tenant, email)

    cond do
      org_admin && OrgAdmin.valid_password?(org_admin, password) ->
        {:ok, org_admin}

      org_admin ->
        {:error, :invalid_password}

      true ->
        # Prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :not_found}
    end
  end
end
