defmodule Wrt.Campaigns do
  @moduledoc """
  The Campaigns context.

  Handles campaign management within a tenant, including:
  - Campaign CRUD operations
  - Campaign lifecycle (draft → active → completed)
  - Campaign admin management
  """

  import Ecto.Query, warn: false
  alias Wrt.Repo
  alias Wrt.Campaigns.{Campaign, CampaignAdmin}

  # =============================================================================
  # Campaign Functions
  # =============================================================================

  @doc """
  Lists all campaigns for a tenant.
  """
  def list_campaigns(tenant) do
    Campaign
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Gets the active campaign for a tenant (if any).
  """
  def get_active_campaign(tenant) do
    Campaign
    |> where([c], c.status == "active")
    |> Repo.one(prefix: tenant)
  end

  @doc """
  Checks if there is an active campaign for a tenant.
  """
  def has_active_campaign?(tenant) do
    Campaign
    |> where([c], c.status == "active")
    |> Repo.exists?(prefix: tenant)
  end

  @doc """
  Gets a campaign by ID.
  """
  def get_campaign(tenant, id) do
    Repo.get(Campaign, id, prefix: tenant)
  end

  @doc """
  Gets a campaign by ID, raising if not found.
  """
  def get_campaign!(tenant, id) do
    Repo.get!(Campaign, id, prefix: tenant)
  end

  @doc """
  Creates a new campaign.

  Returns error if there is already an active campaign.
  """
  def create_campaign(tenant, attrs) do
    if has_active_campaign?(tenant) do
      {:error, :active_campaign_exists}
    else
      %Campaign{}
      |> Campaign.changeset(attrs)
      |> Repo.insert(prefix: tenant)
    end
  end

  @doc """
  Updates a campaign.

  Only draft campaigns can be updated.
  """
  def update_campaign(tenant, %Campaign{} = campaign, attrs) do
    if Campaign.draft?(campaign) do
      campaign
      |> Campaign.update_changeset(attrs)
      |> Repo.update(prefix: tenant)
    else
      {:error, :cannot_update_non_draft_campaign}
    end
  end

  @doc """
  Starts a campaign (moves from draft to active).
  """
  def start_campaign(tenant, %Campaign{} = campaign) do
    cond do
      not Campaign.draft?(campaign) ->
        {:error, :campaign_not_draft}

      has_active_campaign?(tenant) ->
        {:error, :active_campaign_exists}

      true ->
        campaign
        |> Campaign.start_changeset()
        |> Repo.update(prefix: tenant)
    end
  end

  @doc """
  Completes a campaign (moves from active to completed).
  """
  def complete_campaign(tenant, %Campaign{} = campaign) do
    if Campaign.active?(campaign) do
      campaign
      |> Campaign.complete_changeset()
      |> Repo.update(prefix: tenant)
    else
      {:error, :campaign_not_active}
    end
  end

  @doc """
  Deletes a campaign.

  Only draft campaigns can be deleted.
  """
  def delete_campaign(tenant, %Campaign{} = campaign) do
    if Campaign.draft?(campaign) do
      Repo.delete(campaign, prefix: tenant)
    else
      {:error, :cannot_delete_non_draft_campaign}
    end
  end

  @doc """
  Returns a changeset for tracking campaign changes.
  """
  def change_campaign(%Campaign{} = campaign, attrs \\ %{}) do
    Campaign.changeset(campaign, attrs)
  end

  # =============================================================================
  # Campaign Admin Functions
  # =============================================================================

  @doc """
  Lists all campaign admins for a campaign.
  """
  def list_campaign_admins(tenant, campaign_id) do
    CampaignAdmin
    |> where([ca], ca.campaign_id == ^campaign_id)
    |> order_by([ca], asc: ca.name)
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Gets a campaign admin by ID.
  """
  def get_campaign_admin(tenant, id) do
    Repo.get(CampaignAdmin, id, prefix: tenant)
  end

  @doc """
  Gets a campaign admin by email for a specific campaign.
  """
  def get_campaign_admin_by_email(tenant, campaign_id, email) do
    CampaignAdmin
    |> where([ca], ca.campaign_id == ^campaign_id and ca.email == ^String.downcase(email))
    |> Repo.one(prefix: tenant)
  end

  @doc """
  Invites a campaign admin.
  """
  def invite_campaign_admin(tenant, attrs) do
    %CampaignAdmin{}
    |> CampaignAdmin.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Removes a campaign admin.
  """
  def remove_campaign_admin(tenant, %CampaignAdmin{} = campaign_admin) do
    Repo.delete(campaign_admin, prefix: tenant)
  end

  @doc """
  Authenticates a campaign admin.
  """
  def authenticate_campaign_admin(tenant, campaign_id, email, password) do
    campaign_admin = get_campaign_admin_by_email(tenant, campaign_id, email)

    cond do
      campaign_admin && CampaignAdmin.valid_password?(campaign_admin, password) ->
        {:ok, campaign_admin}

      campaign_admin ->
        {:error, :invalid_password}

      true ->
        Bcrypt.no_user_verify()
        {:error, :not_found}
    end
  end
end
