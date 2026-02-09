defmodule WrtWeb.Org.RoundControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    {org, tenant} = create_org_with_tenant()
    admin = insert_in_tenant(tenant, :org_admin)
    campaign = insert_in_tenant(tenant, :campaign)

    # Add seed people for round start
    insert_in_tenant(tenant, :seed_person)
    insert_in_tenant(tenant, :seed_person)

    %{org: org, tenant: tenant, admin: admin, campaign: campaign}
  end

  describe "GET /org/:org_slug/campaigns/:campaign_id/rounds" do
    test "lists rounds when authenticated", %{
      conn: conn,
      org: org,
      admin: admin,
      campaign: campaign
    } do
      conn =
        conn
        |> log_in_org_admin(admin)
        |> get("/org/#{org.slug}/campaigns/#{campaign.id}/rounds")

      assert html_response(conn, 200)
    end

    test "redirects to login when not authenticated", %{conn: conn, org: org, campaign: campaign} do
      conn = get(conn, "/org/#{org.slug}/campaigns/#{campaign.id}/rounds")
      assert redirected_to(conn) == "/org/#{org.slug}/login"
    end
  end

  describe "POST /org/:org_slug/campaigns/:campaign_id/rounds" do
    test "creates and starts a round", %{
      conn: conn,
      org: org,
      admin: admin,
      campaign: campaign
    } do
      conn =
        conn
        |> log_in_org_admin(admin)
        |> post("/org/#{org.slug}/campaigns/#{campaign.id}/rounds", %{
          round: %{duration_days: "7"}
        })

      assert redirected_to(conn) =~ "/rounds/"
    end
  end

  describe "GET /org/:org_slug/campaigns/:campaign_id/rounds/:id" do
    test "shows round details", %{
      conn: conn,
      org: org,
      tenant: tenant,
      admin: admin,
      campaign: campaign
    } do
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      conn =
        conn
        |> log_in_org_admin(admin)
        |> get("/org/#{org.slug}/campaigns/#{campaign.id}/rounds/#{round.id}")

      assert html_response(conn, 200)
    end
  end

  describe "POST close round" do
    test "closes an active round", %{
      conn: conn,
      org: org,
      tenant: tenant,
      admin: admin,
      campaign: campaign
    } do
      round =
        insert_in_tenant(tenant, :active_round, %{campaign_id: campaign.id, round_number: 1})

      conn =
        conn
        |> log_in_org_admin(admin)
        |> post("/org/#{org.slug}/campaigns/#{campaign.id}/rounds/#{round.id}/close")

      assert redirected_to(conn) =~ "/rounds"
    end

    test "shows error when round not active", %{
      conn: conn,
      org: org,
      tenant: tenant,
      admin: admin,
      campaign: campaign
    } do
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      conn =
        conn
        |> log_in_org_admin(admin)
        |> post("/org/#{org.slug}/campaigns/#{campaign.id}/rounds/#{round.id}/close")

      assert redirected_to(conn) =~ "/rounds"
    end
  end

  describe "POST extend round" do
    test "extends an active round", %{
      conn: conn,
      org: org,
      tenant: tenant,
      admin: admin,
      campaign: campaign
    } do
      round =
        insert_in_tenant(tenant, :active_round, %{campaign_id: campaign.id, round_number: 1})

      conn =
        conn
        |> log_in_org_admin(admin)
        |> post("/org/#{org.slug}/campaigns/#{campaign.id}/rounds/#{round.id}/extend", %{
          extension: %{days: "7"}
        })

      assert redirected_to(conn) =~ "/rounds"
    end
  end
end
