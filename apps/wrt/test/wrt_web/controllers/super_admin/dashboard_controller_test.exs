defmodule WrtWeb.SuperAdmin.DashboardControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    admin = Wrt.Repo.insert!(build(:super_admin))
    %{admin: admin}
  end

  describe "GET /admin/dashboard" do
    test "renders dashboard when authenticated via Portal", %{conn: conn, admin: admin} do
      conn =
        conn
        |> log_in_portal_super_admin(admin)
        |> get("/admin/dashboard")

      assert html_response(conn, 200) =~ "Dashboard"
    end

    test "redirects to Portal login when not authenticated", %{conn: conn} do
      conn = get(conn, "/admin/dashboard")
      assert redirected_to(conn)
    end
  end
end
