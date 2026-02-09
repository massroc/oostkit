defmodule WrtWeb.SuperAdmin.OrgControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    admin = Wrt.Repo.insert!(build(:super_admin))
    %{admin: admin}
  end

  describe "GET /admin/orgs" do
    test "lists all organisations when authenticated", %{conn: conn, admin: admin} do
      Wrt.Repo.insert!(build(:organisation))

      conn =
        conn
        |> log_in_super_admin(admin)
        |> get("/admin/orgs")

      assert html_response(conn, 200) =~ "Organisation"
    end

    test "filters by status", %{conn: conn, admin: admin} do
      Wrt.Repo.insert!(build(:organisation, status: "pending"))
      Wrt.Repo.insert!(build(:approved_organisation))

      conn =
        conn
        |> log_in_super_admin(admin)
        |> get("/admin/orgs?status=pending")

      assert html_response(conn, 200)
    end

    test "redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, "/admin/orgs")
      assert redirected_to(conn) == "/admin/login"
    end
  end

  describe "GET /admin/orgs/:id" do
    test "shows organisation details", %{conn: conn, admin: admin} do
      org = Wrt.Repo.insert!(build(:organisation))

      conn =
        conn
        |> log_in_super_admin(admin)
        |> get("/admin/orgs/#{org.id}")

      assert html_response(conn, 200) =~ org.name
    end
  end

  describe "POST /admin/orgs/:id/reject" do
    test "rejects a pending organisation", %{conn: conn, admin: admin} do
      org = Wrt.Repo.insert!(build(:organisation, status: "pending"))

      conn =
        conn
        |> log_in_super_admin(admin)
        |> post("/admin/orgs/#{org.id}/reject", %{reason: "Not valid"})

      assert redirected_to(conn) == "/admin/orgs"
    end
  end

  describe "POST /admin/orgs/:id/suspend" do
    test "suspends an approved organisation", %{conn: conn, admin: admin} do
      org = Wrt.Repo.insert!(build(:approved_organisation))

      conn =
        conn
        |> log_in_super_admin(admin)
        |> post("/admin/orgs/#{org.id}/suspend", %{reason: "Terms violation"})

      assert redirected_to(conn) == "/admin/orgs"
    end
  end
end
