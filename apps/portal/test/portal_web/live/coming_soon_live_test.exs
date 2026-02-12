defmodule PortalWeb.ComingSoonLiveTest do
  use PortalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Portal.Marketing

  describe "GET /coming-soon" do
    test "renders default heading", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/coming-soon")

      assert html =~ "More tools are on the way"
      assert has_element?(view, "input[name='interest_signup[email]']")
    end

    test "renders signup context heading", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/coming-soon?context=signup")

      assert html =~ "Sign up is coming soon"
    end

    test "renders login context heading", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/coming-soon?context=login")

      assert html =~ "Login is coming soon"
    end

    test "renders tool context heading", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/coming-soon?context=tool&name=WRT")

      assert html =~ "WRT is coming soon"
    end

    test "submitting form creates signup and shows success", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/coming-soon?context=signup")

      view
      |> form("form", interest_signup: %{name: "Jane", email: "jane@example.com"})
      |> render_submit()

      assert render(view) =~ "Thanks!"
      assert Marketing.count_interest_signups() == 1
    end

    test "submitting with invalid email does not show success", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/coming-soon")

      view
      |> form("form", interest_signup: %{email: ""})
      |> render_submit()

      refute render(view) =~ "Thanks!"
      assert Marketing.count_interest_signups() == 0
    end

    test "stores context in signup record", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/coming-soon?context=tool&name=WRT")

      view
      |> form("form", interest_signup: %{email: "ctx@example.com"})
      |> render_submit()

      [signup] = Marketing.list_interest_signups()
      assert signup.context == "tool:WRT"
    end
  end
end
