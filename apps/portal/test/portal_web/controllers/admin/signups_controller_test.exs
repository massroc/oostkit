defmodule PortalWeb.Admin.SignupsControllerTest do
  use PortalWeb.ConnCase, async: true

  import Portal.AccountsFixtures

  alias Portal.Marketing

  describe "export" do
    test "unauthenticated user is redirected", %{conn: conn} do
      conn = get(conn, ~p"/admin/signups/export")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "session manager is redirected", %{conn: conn} do
      conn =
        conn
        |> log_in_user(session_manager_fixture())
        |> get(~p"/admin/signups/export")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "super admin"
    end

    test "super admin can export CSV", %{conn: conn} do
      Marketing.create_interest_signup(%{
        email: "test@example.com",
        name: "Test User",
        context: "signup"
      })

      conn =
        conn
        |> log_in_user(super_admin_fixture())
        |> get(~p"/admin/signups/export")

      assert response_content_type(conn, :csv) =~ "text/csv"
      assert conn.resp_body =~ "Name,Email,Context,Date"
      assert conn.resp_body =~ "test@example.com"
      assert conn.resp_body =~ "Test User"
      assert conn.resp_body =~ "signup"
    end

    test "CSV export with empty signups", %{conn: conn} do
      conn =
        conn
        |> log_in_user(super_admin_fixture())
        |> get(~p"/admin/signups/export")

      assert response_content_type(conn, :csv) =~ "text/csv"
      assert conn.resp_body =~ "Name,Email,Context,Date"
    end
  end
end
