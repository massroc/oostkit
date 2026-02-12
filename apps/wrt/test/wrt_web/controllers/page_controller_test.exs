defmodule WrtWeb.PageControllerTest do
  use WrtWeb.ConnCase, async: true

  describe "GET /" do
    test "shows landing page when user has an active org", %{conn: conn} do
      org = Wrt.Repo.insert!(build(:approved_organisation, admin_email: "user@example.com"))
      _tenant = Wrt.DataCase.create_tenant_tables("tenant_#{org.id}")

      conn =
        conn
        |> log_in_portal_user(%{id: 1, email: "user@example.com"})
        |> get("/")

      assert html_response(conn, 200) =~ "Workshop Referral Tool"
      assert html_response(conn, 200) =~ "How the Referral Process Works"
    end

    test "redirects to manage when skip cookie is set", %{conn: conn} do
      org = Wrt.Repo.insert!(build(:approved_organisation, admin_email: "skip@example.com"))
      _tenant = Wrt.DataCase.create_tenant_tables("tenant_#{org.id}")

      conn =
        conn
        |> log_in_portal_user(%{id: 1, email: "skip@example.com"})
        |> put_req_cookie("wrt_skip_landing", "1")
        |> get("/")

      assert redirected_to(conn) == "/org/#{org.slug}/manage"
    end

    test "shows no-org page when user has no organisation", %{conn: conn} do
      conn =
        conn
        |> log_in_portal_user(%{id: 1, email: "nobody@example.com"})
        |> get("/")

      assert html_response(conn, 200) =~ "No Organisation Found"
    end

    test "shows inactive page when org is pending", %{conn: conn} do
      Wrt.Repo.insert!(
        build(:organisation, admin_email: "pending@example.com", status: "pending")
      )

      conn =
        conn
        |> log_in_portal_user(%{id: 1, email: "pending@example.com"})
        |> get("/")

      assert html_response(conn, 200) =~ "Organisation Inactive"
      assert html_response(conn, 200) =~ "pending approval"
    end

    test "redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, "/")
      assert redirected_to(conn)
    end
  end

  describe "POST /dismiss-landing" do
    test "sets skip cookie and redirects to manage", %{conn: conn} do
      org = Wrt.Repo.insert!(build(:approved_organisation, admin_email: "dismiss@example.com"))
      _tenant = Wrt.DataCase.create_tenant_tables("tenant_#{org.id}")

      conn =
        conn
        |> log_in_portal_user(%{id: 1, email: "dismiss@example.com"})
        |> post("/dismiss-landing", %{"skip" => "true"})

      assert redirected_to(conn) == "/org/#{org.slug}/manage"
      assert conn.resp_cookies["wrt_skip_landing"]
    end

    test "redirects without cookie when skip is not checked", %{conn: conn} do
      org =
        Wrt.Repo.insert!(build(:approved_organisation, admin_email: "noskip@example.com"))

      _tenant = Wrt.DataCase.create_tenant_tables("tenant_#{org.id}")

      conn =
        conn
        |> log_in_portal_user(%{id: 1, email: "noskip@example.com"})
        |> post("/dismiss-landing", %{})

      assert redirected_to(conn) == "/org/#{org.slug}/manage"
      refute conn.resp_cookies["wrt_skip_landing"]
    end
  end
end
