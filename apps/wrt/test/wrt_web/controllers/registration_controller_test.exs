defmodule WrtWeb.RegistrationControllerTest do
  use WrtWeb.ConnCase, async: true

  describe "GET /register" do
    test "renders registration form", %{conn: conn} do
      conn = get(conn, "/register")
      assert html_response(conn, 200) =~ "register"
    end
  end

  describe "POST /register" do
    test "creates org and redirects on valid data", %{conn: conn} do
      params = %{
        organisation: %{
          name: "Test Org",
          admin_name: "Admin Person",
          admin_email: "admin@testorg.com"
        }
      }

      conn = post(conn, "/register", params)
      assert redirected_to(conn) == "/"
    end

    test "re-renders form on invalid data", %{conn: conn} do
      conn = post(conn, "/register", %{organisation: %{}})
      assert html_response(conn, 200) =~ "register"
    end
  end
end
