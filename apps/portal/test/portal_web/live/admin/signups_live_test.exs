defmodule PortalWeb.Admin.SignupsLiveTest do
  use PortalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Portal.AccountsFixtures

  alias Portal.Marketing

  describe "authorization" do
    test "unauthenticated user redirects to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/signups")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "session manager redirects to /", %{conn: conn} do
      session_manager = session_manager_fixture()

      assert {:error, redirect} =
               conn
               |> log_in_user(session_manager)
               |> live(~p"/admin/signups")

      assert {:redirect, %{to: "/", flash: flash}} = redirect
      assert %{"error" => "You must be a super admin to access this page."} = flash
    end
  end

  describe "signups list" do
    setup :register_and_log_in_super_admin

    test "renders empty state", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/signups")

      assert html =~ "Email Signups"
      assert html =~ "No signups yet."
    end

    test "lists signups", %{conn: conn} do
      Marketing.create_interest_signup(%{
        email: "alice@example.com",
        name: "Alice",
        context: "signup"
      })

      Marketing.create_interest_signup(%{email: "bob@example.com", name: "Bob", context: "login"})

      {:ok, _lv, html} = live(conn, ~p"/admin/signups")

      assert html =~ "alice@example.com"
      assert html =~ "Alice"
      assert html =~ "bob@example.com"
      assert html =~ "Bob"
      assert html =~ "2 signups captured"
    end

    test "displays context badges", %{conn: conn} do
      Marketing.create_interest_signup(%{email: "a@example.com", context: "tool:wrt"})

      {:ok, _lv, html} = live(conn, ~p"/admin/signups")
      assert html =~ "tool:wrt"
    end
  end

  describe "search" do
    setup :register_and_log_in_super_admin

    test "filters signups by search query", %{conn: conn} do
      Marketing.create_interest_signup(%{email: "alice@example.com", name: "Alice"})
      Marketing.create_interest_signup(%{email: "bob@example.com", name: "Bob"})

      {:ok, lv, _html} = live(conn, ~p"/admin/signups")

      html =
        lv
        |> element("form")
        |> render_change(%{query: "alice"})

      assert html =~ "alice@example.com"
      refute html =~ "bob@example.com"
    end

    test "shows all when search is cleared", %{conn: conn} do
      Marketing.create_interest_signup(%{email: "alice@example.com"})
      Marketing.create_interest_signup(%{email: "bob@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/admin/signups")

      lv |> element("form") |> render_change(%{query: "alice"})

      html = lv |> element("form") |> render_change(%{query: ""})

      assert html =~ "alice@example.com"
      assert html =~ "bob@example.com"
    end
  end

  describe "delete" do
    setup :register_and_log_in_super_admin

    test "deletes a signup", %{conn: conn} do
      {:ok, signup} =
        Marketing.create_interest_signup(%{email: "delete@example.com", name: "Del"})

      {:ok, lv, html} = live(conn, ~p"/admin/signups")
      assert html =~ "delete@example.com"

      lv
      |> element(~s|button[phx-click="delete_signup"][phx-value-id="#{signup.id}"]|)
      |> render_click()

      html = render(lv)
      assert html =~ "Signup deleted."
      refute html =~ "delete@example.com"
    end
  end

  describe "export link" do
    setup :register_and_log_in_super_admin

    test "export CSV link is present", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/signups")
      assert html =~ ~s|href="/admin/signups/export"|
      assert html =~ "Export CSV"
    end
  end
end
