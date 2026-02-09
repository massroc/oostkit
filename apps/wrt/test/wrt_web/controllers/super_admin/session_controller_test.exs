defmodule WrtWeb.SuperAdmin.SessionControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    admin = Wrt.Repo.insert!(build(:super_admin, email: "admin@test.com"))
    %{admin: admin}
  end

  describe "GET /admin/login" do
    test "renders login form", %{conn: conn} do
      conn = get(conn, "/admin/login")
      assert html_response(conn, 200) =~ "login"
    end
  end

  describe "POST /admin/login" do
    test "redirects to dashboard with valid credentials", %{conn: conn, admin: admin} do
      conn =
        post(conn, "/admin/login", %{admin: %{email: admin.email, password: "password123"}})

      assert redirected_to(conn) == "/admin/dashboard"
      assert get_session(conn, :super_admin_id) == admin.id
    end

    test "re-renders login with invalid password", %{conn: conn, admin: admin} do
      conn =
        post(conn, "/admin/login", %{admin: %{email: admin.email, password: "wrong"}})

      assert html_response(conn, 200) =~ "Invalid email or password"
    end

    test "re-renders login with non-existent email", %{conn: conn} do
      conn =
        post(conn, "/admin/login", %{admin: %{email: "nobody@test.com", password: "password123"}})

      assert html_response(conn, 200) =~ "Invalid email or password"
    end
  end

  describe "DELETE /admin/logout" do
    test "logs out and redirects to login", %{conn: conn, admin: admin} do
      conn =
        conn
        |> log_in_super_admin(admin)
        |> delete("/admin/logout")

      assert redirected_to(conn) == "/admin/login"
    end
  end
end
