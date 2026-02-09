defmodule WrtWeb.SuperAdmin.DashboardControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    admin = Wrt.Repo.insert!(build(:super_admin))
    %{admin: admin}
  end

  describe "GET /admin/dashboard" do
    test "renders dashboard when authenticated", %{conn: conn, admin: admin} do
      conn =
        conn
        |> log_in_super_admin(admin)
        |> get("/admin/dashboard")

      assert html_response(conn, 200) =~ "dashboard"
    end

    test "redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, "/admin/dashboard")
      assert redirected_to(conn) == "/admin/login"
    end
  end
end
