defmodule WrtWeb.Plugs.RequirePortalUserTest do
  use WrtWeb.ConnCase, async: true

  alias WrtWeb.Plugs.RequirePortalUser

  describe "call/2" do
    test "passes through when user is authenticated", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> fetch_flash()
        |> assign(:portal_user, %{"id" => 1, "email" => "user@example.com", "enabled" => true})
        |> RequirePortalUser.call([])

      refute conn.halted
    end

    test "redirects to portal login with return_to when unauthenticated", %{conn: conn} do
      conn =
        conn
        |> Map.put(:path_info, ["referrals"])
        |> Map.put(:query_string, "")
        |> init_test_session(%{})
        |> fetch_flash()
        |> RequirePortalUser.call([])

      assert conn.halted
      location = redirected_to(conn)
      assert location =~ "http://localhost:4002/users/log-in"
      assert location =~ "return_to="
      assert location =~ URI.encode_www_form("http://localhost:4003/referrals")
    end

    test "preserves query string in return_to", %{conn: conn} do
      conn =
        conn
        |> Map.put(:path_info, ["org", "acme", "workshops"])
        |> Map.put(:query_string, "page=2&sort=name")
        |> init_test_session(%{})
        |> fetch_flash()
        |> RequirePortalUser.call([])

      assert conn.halted
      location = redirected_to(conn)

      assert location =~
               URI.encode_www_form("http://localhost:4003/org/acme/workshops?page=2&sort=name")
    end

    test "redirects when portal_user is nil", %{conn: conn} do
      conn =
        conn
        |> Map.put(:path_info, [""])
        |> Map.put(:query_string, "")
        |> init_test_session(%{})
        |> fetch_flash()
        |> assign(:portal_user, nil)
        |> RequirePortalUser.call([])

      assert conn.halted
      assert redirected_to(conn) =~ "http://localhost:4002/users/log-in"
    end

    test "redirects when portal_user is not enabled", %{conn: conn} do
      conn =
        conn
        |> Map.put(:path_info, [""])
        |> Map.put(:query_string, "")
        |> init_test_session(%{})
        |> fetch_flash()
        |> assign(:portal_user, %{"id" => 1, "email" => "user@example.com", "enabled" => false})
        |> RequirePortalUser.call([])

      assert conn.halted
      assert redirected_to(conn) =~ "http://localhost:4002/users/log-in"
    end
  end
end
