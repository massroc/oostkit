defmodule WrtWeb.Org.SessionControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    {org, tenant} = create_org_with_tenant()
    admin = insert_in_tenant(tenant, :org_admin, %{email: "orgadmin@test.com"})
    %{org: org, tenant: tenant, admin: admin}
  end

  describe "GET /org/:org_slug/login" do
    test "renders login form", %{conn: conn, org: org} do
      conn = get(conn, "/org/#{org.slug}/login")
      assert html_response(conn, 200) =~ "login"
    end

    test "returns 404 for non-existent org", %{conn: conn} do
      conn = get(conn, "/org/nonexistent-org/login")
      assert html_response(conn, 404)
    end
  end

  describe "POST /org/:org_slug/login" do
    test "redirects to dashboard with valid credentials", %{conn: conn, org: org, admin: admin} do
      conn =
        post(conn, "/org/#{org.slug}/login", %{
          admin: %{email: admin.email, password: "password123"}
        })

      assert redirected_to(conn) == "/org/#{org.slug}/dashboard"
      assert get_session(conn, :org_admin_id) == admin.id
    end

    test "re-renders login with invalid password", %{conn: conn, org: org, admin: admin} do
      conn =
        post(conn, "/org/#{org.slug}/login", %{
          admin: %{email: admin.email, password: "wrong"}
        })

      assert html_response(conn, 200) =~ "Invalid"
    end
  end

  describe "DELETE /org/:org_slug/logout" do
    test "logs out and redirects to login", %{conn: conn, org: org, admin: admin} do
      conn =
        conn
        |> log_in_org_admin(admin)
        |> delete("/org/#{org.slug}/logout")

      assert redirected_to(conn) == "/org/#{org.slug}/login"
    end
  end
end
