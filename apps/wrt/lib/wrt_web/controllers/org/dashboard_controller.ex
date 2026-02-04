defmodule WrtWeb.Org.DashboardController do
  use WrtWeb, :controller

  alias Wrt.Campaigns
  alias Wrt.Rounds

  plug WrtWeb.Plugs.TenantPlug
  plug WrtWeb.Plugs.RequireOrgAdmin

  def index(conn, _params) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaigns = Campaigns.list_campaigns(tenant)
    active_campaign = Campaigns.get_active_campaign(tenant)

    active_round =
      if active_campaign do
        Rounds.get_active_round(tenant, active_campaign.id)
      end

    render(conn, :index,
      page_title: "Dashboard",
      org: org,
      campaigns: campaigns,
      active_campaign: active_campaign,
      active_round: active_round
    )
  end
end
