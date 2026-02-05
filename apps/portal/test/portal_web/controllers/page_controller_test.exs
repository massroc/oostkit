defmodule PortalWeb.PageControllerTest do
  use PortalWeb.ConnCase

  describe "GET /" do
    test "renders the home page with app cards", %{conn: conn} do
      conn = get(conn, ~p"/")

      assert html_response(conn, 200) =~ "OOSTKit"
      assert html_response(conn, 200) =~ "Tools for Facilitators"
      assert html_response(conn, 200) =~ "Tools for Teams"
      assert html_response(conn, 200) =~ "Workgroup Pulse"
      assert html_response(conn, 200) =~ "Workshop Referral Tool"
    end
  end

  describe "GET /apps/:app_id" do
    test "renders app detail page for valid app", %{conn: conn} do
      conn = get(conn, ~p"/apps/workgroup_pulse")

      assert html_response(conn, 200) =~ "Workgroup Pulse"
      assert html_response(conn, 200) =~ "6 Criteria for Productive Work"
      assert html_response(conn, 200) =~ "Launch"
    end

    test "renders app detail page for wrt", %{conn: conn} do
      conn = get(conn, ~p"/apps/wrt")

      assert html_response(conn, 200) =~ "Workshop Referral Tool"
      assert html_response(conn, 200) =~ "This tool requires login"
    end

    test "redirects to home for invalid app", %{conn: conn} do
      conn = get(conn, ~p"/apps/nonexistent")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Application not found"
    end
  end
end
