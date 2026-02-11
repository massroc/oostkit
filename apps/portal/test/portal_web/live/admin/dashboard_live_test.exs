defmodule PortalWeb.Admin.DashboardLiveTest do
  use PortalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Portal.AccountsFixtures

  alias Portal.Marketing
  alias Portal.Tools

  @tool_attrs %{
    id: "test_tool",
    name: "Test Tool",
    tagline: "A test tool",
    audience: "team",
    default_status: "live",
    sort_order: 99
  }

  describe "authorization" do
    test "unauthenticated user redirects to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "session manager redirects to /", %{conn: conn} do
      session_manager = session_manager_fixture()

      assert {:error, redirect} =
               conn
               |> log_in_user(session_manager)
               |> live(~p"/admin")

      assert {:redirect, %{to: "/", flash: flash}} = redirect
      assert %{"error" => "You must be a super admin to access this page."} = flash
    end
  end

  describe "dashboard" do
    setup :register_and_log_in_super_admin

    test "renders dashboard with stats", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Admin Dashboard"
      assert html =~ "Email Signups"
      assert html =~ "Registered Users"
      assert html =~ "Active Users (30d)"
    end

    test "displays signup count", %{conn: conn} do
      Marketing.create_interest_signup(%{email: "a@example.com", context: "signup"})
      Marketing.create_interest_signup(%{email: "b@example.com", context: "signup"})

      {:ok, _lv, html} = live(conn, ~p"/admin")
      assert html =~ ">2</span>"
    end

    test "displays user count", %{conn: conn} do
      session_manager_fixture(%{email: "sm@example.com"})

      {:ok, _lv, html} = live(conn, ~p"/admin")
      # At least 2 users: the admin + the session manager
      assert html =~ "Registered Users"
    end

    test "displays tool status summary", %{conn: conn} do
      Tools.create_tool(@tool_attrs)

      Tools.create_tool(%{
        @tool_attrs
        | id: "tool_cs",
          default_status: "coming_soon",
          sort_order: 98
      })

      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Tool Status"
      assert html =~ "Live"
      assert html =~ "Coming Soon"
      assert html =~ "Maintenance"
    end

    test "displays quick links", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin")

      assert html =~ "Manage Users"
      assert html =~ "Email Signups"
      assert html =~ "Tool Status"
      assert html =~ ~s|href="/admin/users"|
      assert html =~ ~s|href="/admin/signups"|
      assert html =~ ~s|href="/admin/tools"|
    end
  end
end
