defmodule WrtWeb.Org.ResultsControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    {org, tenant} = create_org_with_tenant()
    admin = insert_in_tenant(tenant, :org_admin)
    campaign = insert_in_tenant(tenant, :campaign)
    %{org: org, tenant: tenant, admin: admin, campaign: campaign}
  end

  describe "GET /org/:org_slug/campaigns/:campaign_id/results" do
    test "renders results page when authenticated", %{
      conn: conn,
      org: org,
      admin: admin,
      campaign: campaign
    } do
      conn =
        conn
        |> log_in_org_admin(admin)
        |> get("/org/#{org.slug}/campaigns/#{campaign.id}/results")

      assert html_response(conn, 200) =~ "Results"
    end

    test "redirects to login when not authenticated", %{
      conn: conn,
      org: org,
      campaign: campaign
    } do
      conn = get(conn, "/org/#{org.slug}/campaigns/#{campaign.id}/results")
      assert redirected_to(conn) == "/org/#{org.slug}/login"
    end

    test "shows nominees with nomination counts", %{
      conn: conn,
      org: org,
      tenant: tenant,
      admin: admin,
      campaign: campaign
    } do
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      nominator = insert_in_tenant(tenant, :person)
      nominee = insert_in_tenant(tenant, :person, %{name: "Popular Nominee"})

      Wrt.Repo.insert!(
        build(:nomination, %{
          round_id: round.id,
          nominator_id: nominator.id,
          nominee_id: nominee.id
        }),
        prefix: tenant
      )

      conn =
        conn
        |> log_in_org_admin(admin)
        |> get("/org/#{org.slug}/campaigns/#{campaign.id}/results")

      assert html_response(conn, 200) =~ "Popular Nominee"
    end
  end
end
