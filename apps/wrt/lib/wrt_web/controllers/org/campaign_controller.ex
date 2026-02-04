defmodule WrtWeb.Org.CampaignController do
  use WrtWeb, :controller

  alias Wrt.Campaigns
  alias Wrt.Campaigns.Campaign
  alias Wrt.People
  alias Wrt.Rounds

  plug WrtWeb.Plugs.TenantPlug
  plug WrtWeb.Plugs.RequireOrgAdmin

  def new(conn, _params) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    if Campaigns.has_active_campaign?(tenant) do
      conn
      |> put_flash(
        :error,
        "You already have an active campaign. Complete or archive it before creating a new one."
      )
      |> redirect(to: ~p"/org/#{org.slug}/dashboard")
    else
      changeset = Campaigns.change_campaign(%Campaign{})

      render(conn, :new,
        page_title: "New Campaign",
        org: org,
        changeset: changeset
      )
    end
  end

  def create(conn, %{"campaign" => campaign_params}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    case Campaigns.create_campaign(tenant, campaign_params) do
      {:ok, campaign} ->
        conn
        |> put_flash(:info, "Campaign created successfully.")
        |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}")

      {:error, :active_campaign_exists} ->
        conn
        |> put_flash(:error, "You already have an active campaign.")
        |> redirect(to: ~p"/org/#{org.slug}/dashboard")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new,
          page_title: "New Campaign",
          org: org,
          changeset: changeset
        )
    end
  end

  def show(conn, %{"id" => id}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, id)
    rounds = Rounds.list_rounds(tenant, campaign.id)
    active_round = Rounds.get_active_round(tenant, campaign.id)
    seed_count = length(People.list_seed_people(tenant))
    people_counts = People.count_people_by_source(tenant)

    render(conn, :show,
      page_title: campaign.name,
      org: org,
      campaign: campaign,
      rounds: rounds,
      active_round: active_round,
      seed_count: seed_count,
      people_counts: people_counts
    )
  end
end
