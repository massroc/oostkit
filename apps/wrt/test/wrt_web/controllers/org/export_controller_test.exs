defmodule WrtWeb.Org.ExportControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    {org, tenant} = create_org_with_tenant()
    admin = insert_in_tenant(tenant, :org_admin)
    campaign = insert_in_tenant(tenant, :campaign)
    round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
    nominator = insert_in_tenant(tenant, :person)
    nominee = insert_in_tenant(tenant, :person, %{name: "Test Nominee"})

    Wrt.Repo.insert!(
      build(:nomination, %{
        round_id: round.id,
        nominator_id: nominator.id,
        nominee_id: nominee.id
      }),
      prefix: tenant
    )

    %{org: org, tenant: tenant, admin: admin, campaign: campaign}
  end

  describe "GET /org/:org_slug/campaigns/:campaign_id/export/csv" do
    test "returns CSV download", %{conn: conn, org: org, admin: admin, campaign: campaign} do
      conn =
        conn
        |> log_in_portal_user(admin)
        |> get("/org/#{org.slug}/campaigns/#{campaign.id}/export/csv")

      assert response_content_type(conn, :csv) =~ "text/csv"
      body = response(conn, 200)
      assert body =~ "Rank"
      assert body =~ "Test Nominee"
    end

    test "redirects to login when not authenticated", %{
      conn: conn,
      org: org,
      campaign: campaign
    } do
      conn = get(conn, "/org/#{org.slug}/campaigns/#{campaign.id}/export/csv")
      assert redirected_to(conn)
    end
  end

  # PDF export requires ChromicPDF supervisor which is not started in test
  # Tested in dev environment via manual inspection
end
