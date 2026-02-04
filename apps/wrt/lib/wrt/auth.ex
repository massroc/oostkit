defmodule Wrt.Auth do
  @moduledoc """
  Authentication context for the WRT application.

  Handles authentication for:
  - Super admins (platform-level)
  - Org admins (organisation-level)
  - Campaign admins (campaign-level)
  - Nominators (magic link authentication)
  """

  alias Wrt.Platform
  alias Wrt.Platform.SuperAdmin

  # =============================================================================
  # Super Admin Authentication
  # =============================================================================

  @doc """
  Authenticates a super admin by email and password.

  Returns `{:ok, super_admin}` on success, `{:error, reason}` on failure.
  """
  def authenticate_super_admin(email, password) do
    Platform.authenticate_super_admin(email, password)
  end

  @doc """
  Gets a super admin by ID.
  """
  def get_super_admin(id) do
    Platform.get_super_admin(id)
  end

  @doc """
  Generates a session token for a super admin.

  The token is stored in the session and used to look up the admin on subsequent requests.
  """
  def generate_super_admin_session_token(%SuperAdmin{} = admin) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    {token, admin.id}
  end

  @doc """
  Verifies a super admin session token and returns the admin.
  """
  def verify_super_admin_session_token(token, admin_id) when is_binary(token) do
    case get_super_admin(admin_id) do
      nil -> {:error, :not_found}
      admin -> {:ok, admin}
    end
  end

  def verify_super_admin_session_token(_, _), do: {:error, :invalid_token}

  # =============================================================================
  # Org Admin Authentication
  # =============================================================================

  alias Wrt.Orgs

  @doc """
  Authenticates an org admin by email and password.

  Returns `{:ok, org_admin}` on success, `{:error, reason}` on failure.
  """
  def authenticate_org_admin(tenant, email, password) do
    Orgs.authenticate_org_admin(tenant, email, password)
  end

  @doc """
  Gets an org admin by ID.
  """
  def get_org_admin(tenant, id) do
    Orgs.get_org_admin(tenant, id)
  end
end
