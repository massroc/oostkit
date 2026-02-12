defmodule WrtWeb.Org.CampaignControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    {org, tenant} = create_org_with_tenant()
    admin = insert_in_tenant(tenant, :org_admin)
    %{org: org, tenant: tenant, admin: admin}
  end

  describe "GET /org/:org_slug/campaigns/new" do
    test "renders new campaign form when authenticated", %{conn: conn, org: org, admin: admin} do
      conn =
        conn
        |> log_in_portal_user(admin)
        |> get("/org/#{org.slug}/campaigns/new")

      assert html_response(conn, 200) =~ "campaign"
    end

    test "redirects to dashboard if active campaign exists", %{
      conn: conn,
      org: org,
      tenant: tenant,
      admin: admin
    } do
      insert_in_tenant(tenant, :active_campaign)

      conn =
        conn
        |> log_in_portal_user(admin)
        |> get("/org/#{org.slug}/campaigns/new")

      assert redirected_to(conn) == "/org/#{org.slug}/manage"
    end

    test "redirects to login when not authenticated", %{conn: conn, org: org} do
      conn = get(conn, "/org/#{org.slug}/campaigns/new")
      assert redirected_to(conn)
    end
  end

  describe "POST /org/:org_slug/campaigns" do
    test "creates campaign and redirects to show", %{conn: conn, org: org, admin: admin} do
      params = %{campaign: %{name: "New Campaign", description: "Test"}}

      conn =
        conn
        |> log_in_portal_user(admin)
        |> post("/org/#{org.slug}/campaigns", params)

      assert redirected_to(conn) =~ "/org/#{org.slug}/campaigns/"
    end

    test "re-renders form on invalid data", %{conn: conn, org: org, admin: admin} do
      params = %{campaign: %{name: ""}}

      conn =
        conn
        |> log_in_portal_user(admin)
        |> post("/org/#{org.slug}/campaigns", params)

      assert html_response(conn, 200) =~ "campaign"
    end
  end

  describe "GET /org/:org_slug/campaigns/:id" do
    test "shows campaign details", %{conn: conn, org: org, tenant: tenant, admin: admin} do
      campaign = insert_in_tenant(tenant, :campaign)

      conn =
        conn
        |> log_in_portal_user(admin)
        |> get("/org/#{org.slug}/campaigns/#{campaign.id}")

      assert html_response(conn, 200) =~ campaign.name
    end
  end
end
