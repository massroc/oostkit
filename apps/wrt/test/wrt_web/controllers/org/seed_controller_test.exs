defmodule WrtWeb.Org.SeedControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    {org, tenant} = create_org_with_tenant()
    admin = insert_in_tenant(tenant, :org_admin)
    campaign = insert_in_tenant(tenant, :campaign)
    %{org: org, tenant: tenant, admin: admin, campaign: campaign}
  end

  describe "GET /org/:org_slug/campaigns/:campaign_id/seed" do
    test "renders seed page when authenticated", %{
      conn: conn,
      org: org,
      admin: admin,
      campaign: campaign
    } do
      conn =
        conn
        |> log_in_org_admin(admin)
        |> get("/org/#{org.slug}/campaigns/#{campaign.id}/seed")

      assert html_response(conn, 200)
    end

    test "redirects to login when not authenticated", %{conn: conn, org: org, campaign: campaign} do
      conn = get(conn, "/org/#{org.slug}/campaigns/#{campaign.id}/seed")
      assert redirected_to(conn) == "/org/#{org.slug}/login"
    end
  end

  describe "POST /org/:org_slug/campaigns/:campaign_id/seed/add" do
    test "adds a seed person", %{conn: conn, org: org, admin: admin, campaign: campaign} do
      params = %{person: %{name: "New Seed", email: "seed@test.com"}}

      conn =
        conn
        |> log_in_org_admin(admin)
        |> post("/org/#{org.slug}/campaigns/#{campaign.id}/seed/add", params)

      assert redirected_to(conn) =~ "/seed"
    end

    test "re-renders on invalid data", %{conn: conn, org: org, admin: admin, campaign: campaign} do
      params = %{person: %{name: "", email: ""}}

      conn =
        conn
        |> log_in_org_admin(admin)
        |> post("/org/#{org.slug}/campaigns/#{campaign.id}/seed/add", params)

      assert html_response(conn, 200)
    end
  end

  describe "POST /org/:org_slug/campaigns/:campaign_id/seed/upload" do
    test "imports CSV file", %{conn: conn, org: org, admin: admin, campaign: campaign} do
      csv_content = "name,email\nAlice,alice@test.com\nBob,bob@test.com"

      upload = %Plug.Upload{
        path: write_temp_csv(csv_content),
        filename: "seeds.csv",
        content_type: "text/csv"
      }

      conn =
        conn
        |> log_in_org_admin(admin)
        |> post("/org/#{org.slug}/campaigns/#{campaign.id}/seed/upload", %{csv: upload})

      assert redirected_to(conn) =~ "/seed"
    end

    test "shows error when no file uploaded", %{
      conn: conn,
      org: org,
      admin: admin,
      campaign: campaign
    } do
      conn =
        conn
        |> log_in_org_admin(admin)
        |> post("/org/#{org.slug}/campaigns/#{campaign.id}/seed/upload", %{})

      assert redirected_to(conn) =~ "/seed"
    end
  end

  defp write_temp_csv(content) do
    path = Path.join(System.tmp_dir!(), "test_#{System.unique_integer([:positive])}.csv")
    File.write!(path, content)
    path
  end
end
