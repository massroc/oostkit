defmodule WorkgroupPulseWeb.SessionLive.NewTest do
  use WorkgroupPulseWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "New Workshop page (home)" do
    test "renders welcome heading and create form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Workgroup Pulse"
      assert html =~ "Intrinsic Motivation Assessment"
      assert html =~ "Create Workshop"
      assert html =~ "Your Name"
    end

    test "does not have a back button", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      refute has_element?(view, "a", "Back")
    end
  end
end
