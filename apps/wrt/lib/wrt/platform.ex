defmodule Wrt.Platform do
  @moduledoc """
  The Platform context.

  Handles cross-tenant operations including:
  - Super admin management
  - Organisation registration and approval
  - Platform-wide queries
  """

  import Ecto.Query, warn: false
  alias Wrt.Repo
  alias Wrt.Platform.{Organisation, SuperAdmin}
  alias Wrt.TenantManager

  # =============================================================================
  # Super Admin Functions
  # =============================================================================

  @doc """
  Gets a super admin by ID.
  """
  def get_super_admin(id), do: Repo.get(SuperAdmin, id)

  @doc """
  Gets a super admin by email.
  """
  def get_super_admin_by_email(email) when is_binary(email) do
    Repo.get_by(SuperAdmin, email: String.downcase(email))
  end

  @doc """
  Creates a super admin.
  """
  def create_super_admin(attrs) do
    %SuperAdmin{}
    |> SuperAdmin.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a super admin.
  """
  def update_super_admin(%SuperAdmin{} = super_admin, attrs) do
    super_admin
    |> SuperAdmin.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Authenticates a super admin by email and password.
  """
  def authenticate_super_admin(email, password) do
    super_admin = get_super_admin_by_email(email)

    cond do
      super_admin && SuperAdmin.valid_password?(super_admin, password) ->
        {:ok, super_admin}

      super_admin ->
        {:error, :invalid_password}

      true ->
        # Prevent timing attacks
        Bcrypt.no_user_verify()
        {:error, :not_found}
    end
  end

  # =============================================================================
  # Organisation Functions
  # =============================================================================

  @doc """
  Lists all organisations.
  """
  def list_organisations do
    Organisation
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists organisations by status.
  """
  def list_organisations_by_status(status) when status in ~w(pending approved rejected suspended) do
    Organisation
    |> where([o], o.status == ^status)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists all approved organisations.
  """
  def list_approved_organisations do
    list_organisations_by_status("approved")
  end

  @doc """
  Lists pending organisation requests.
  """
  def list_pending_organisations do
    list_organisations_by_status("pending")
  end

  @doc """
  Gets an organisation by ID.
  """
  def get_organisation(id), do: Repo.get(Organisation, id)

  @doc """
  Gets an organisation by ID, raising if not found.
  """
  def get_organisation!(id), do: Repo.get!(Organisation, id)

  @doc """
  Gets an organisation by slug.
  """
  def get_organisation_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Organisation, slug: String.downcase(slug))
  end

  @doc """
  Registers a new organisation (creates in pending status).
  """
  def register_organisation(attrs) do
    %Organisation{}
    |> Organisation.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Approves an organisation and creates its tenant schema.
  """
  def approve_organisation(%Organisation{} = org, %SuperAdmin{} = super_admin) do
    Repo.transaction(fn ->
      with {:ok, org} <- do_approve_organisation(org, super_admin),
           {:ok, _schema} <- TenantManager.create_tenant(org.id) do
        org
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp do_approve_organisation(org, super_admin) do
    org
    |> Organisation.approve_changeset(super_admin)
    |> Repo.update()
  end

  @doc """
  Rejects an organisation registration request.
  """
  def reject_organisation(%Organisation{} = org, reason \\ nil) do
    org
    |> Organisation.reject_changeset(reason)
    |> Repo.update()
  end

  @doc """
  Suspends an organisation.
  """
  def suspend_organisation(%Organisation{} = org, %SuperAdmin{} = super_admin, reason \\ nil) do
    org
    |> Organisation.suspend_changeset(super_admin, reason)
    |> Repo.update()
  end

  @doc """
  Reactivates a suspended organisation.
  """
  def reactivate_organisation(%Organisation{} = org) do
    org
    |> Organisation.reactivate_changeset()
    |> Repo.update()
  end

  @doc """
  Returns the tenant schema name for an organisation.
  """
  def tenant_for_org(%Organisation{id: id}) do
    TenantManager.tenant_schema_name(id)
  end

  @doc """
  Counts organisations by status.
  """
  def count_organisations_by_status do
    Organisation
    |> group_by([o], o.status)
    |> select([o], {o.status, count(o.id)})
    |> Repo.all()
    |> Map.new()
  end
end
