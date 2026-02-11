defmodule WrtWeb.Org.DashboardController do
  use WrtWeb, :controller

  alias Wrt.Campaigns
  alias Wrt.Reports
  alias Wrt.Rounds

  plug WrtWeb.Plugs.TenantPlug

  def index(conn, _params) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaigns = Campaigns.list_campaigns(tenant)
    active_campaign = Campaigns.get_active_campaign(tenant)

    {active_round, campaign_stats, top_nominees} =
      if active_campaign do
        round = Rounds.get_active_round(tenant, active_campaign.id)
        stats = Reports.get_campaign_stats(tenant, active_campaign.id)
        nominees = Reports.get_top_nominees(tenant, 5)
        {round, stats, nominees}
      else
        {nil, nil, []}
      end

    render(conn, :index,
      page_title: "Dashboard",
      org: org,
      campaigns: campaigns,
      active_campaign: active_campaign,
      active_round: active_round,
      campaign_stats: campaign_stats,
      top_nominees: top_nominees
    )
  end
end
