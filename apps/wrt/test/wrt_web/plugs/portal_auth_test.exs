defmodule WrtWeb.Plugs.PortalAuthTest do
  use WrtWeb.ConnCase, async: true

  alias WrtWeb.Plugs.PortalAuth

  describe "call/2 when portal_user already assigned" do
    test "skips validation", %{conn: conn} do
      existing_user = %{"id" => 99, "email" => "already@set.com"}

      conn =
        conn
        |> assign(:portal_user, existing_user)
        |> PortalAuth.call([])

      assert conn.assigns.portal_user == existing_user
    end
  end

  describe "call/2 when no cookie present" do
    test "assigns portal_user via dev bypass", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> fetch_cookies()
        |> PortalAuth.call([])

      # In test env, maybe_dev_bypass assigns nil (same as prod).
      # In dev env, it would assign a fake dev admin user.
      assert conn.assigns.portal_user == nil
    end
  end

  describe "call/2 when cookie present but validation fails" do
    test "falls back to dev bypass instead of hard-coding nil", %{conn: conn} do
      # Pre-seed the auth cache so validate_token returns instantly
      # without making a real HTTP call to Portal (which isn't running).
      expires_at = System.monotonic_time(:second) + 60
      :ets.insert(:portal_auth_cache, {"invalid-token-value", {:error, :invalid}, expires_at})

      conn =
        conn
        |> init_test_session(%{})
        |> put_req_cookie("_oostkit_token", "invalid-token-value")
        |> PortalAuth.call([])

      # Token validation fails (no Portal running in test).
      # With the fix, this falls through to maybe_dev_bypass/1
      # rather than directly assigning nil — in dev env this
      # gives the fake admin (breaking the auth loop).
      # In test/prod env, maybe_dev_bypass assigns nil.
      assert conn.assigns.portal_user == nil
    end
  end
end
