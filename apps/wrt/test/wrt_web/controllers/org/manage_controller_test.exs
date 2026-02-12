defmodule WrtWeb.Org.ManageControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    {org, tenant} = create_org_with_tenant()
    admin = insert_in_tenant(tenant, :org_admin)
    %{org: org, tenant: tenant, admin: admin}
  end

  describe "GET /org/:org_slug/manage" do
    test "renders process manager when authenticated", %{conn: conn, org: org, admin: admin} do
      conn =
        conn
        |> log_in_portal_user(admin)
        |> get("/org/#{org.slug}/manage")

      assert html_response(conn, 200) =~ "Process Manager"
    end

    test "redirects to login when not authenticated", %{conn: conn, org: org} do
      conn = get(conn, "/org/#{org.slug}/manage")
      assert redirected_to(conn)
    end
  end
end
