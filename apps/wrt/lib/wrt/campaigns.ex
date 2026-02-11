defmodule Wrt.Campaigns do
  @moduledoc """
  The Campaigns context.

  Handles campaign management within a tenant, including:
  - Campaign CRUD operations
  - Campaign lifecycle (draft → active → completed)
  - Campaign admin management
  """

  import Ecto.Query, warn: false

  alias Wrt.Campaigns.Campaign
  alias Wrt.Repo

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
end
