defmodule WrtWeb.Org.ResultsController do
  use WrtWeb, :controller

  alias Wrt.Campaigns
  alias Wrt.People
  alias Wrt.Rounds

  plug WrtWeb.Plugs.TenantPlug
  plug WrtWeb.Plugs.RequireOrgAdmin

  def index(conn, %{"campaign_id" => campaign_id}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)
    rounds = Rounds.list_rounds(tenant, campaign.id)

    # Get people with nomination counts (convergence data)
    people_with_counts = People.list_people_with_nomination_counts(tenant)

    # Filter to only those with nominations
    nominees = Enum.filter(people_with_counts, fn p -> p.nomination_count > 0 end)

    render(conn, :index,
      page_title: "Results",
      org: org,
      campaign: campaign,
      rounds: rounds,
      nominees: nominees
    )
  end
end
