defmodule PortalWeb.Admin.ToolsLiveTest do
  use PortalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Portal.AccountsFixtures

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
      assert {:error, redirect} = live(conn, ~p"/admin/tools")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "session manager redirects to /", %{conn: conn} do
      session_manager = session_manager_fixture()

      assert {:error, redirect} =
               conn
               |> log_in_user(session_manager)
               |> live(~p"/admin/tools")

      assert {:redirect, %{to: "/", flash: flash}} = redirect
      assert %{"error" => "You must be a super admin to access this page."} = flash
    end
  end

  describe "tools list" do
    setup :register_and_log_in_super_admin

    test "renders tool management page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/tools")

      assert html =~ "Tool Management"
      assert html =~ "Control tool visibility"
    end

    test "lists tools with status", %{conn: conn} do
      Tools.create_tool(@tool_attrs)

      Tools.create_tool(%{
        @tool_attrs
        | id: "tool_cs",
          name: "Coming Tool",
          default_status: "coming_soon",
          sort_order: 98
      })

      {:ok, _lv, html} = live(conn, ~p"/admin/tools")

      assert html =~ "Test Tool"
      assert html =~ "Coming Tool"
      assert html =~ "Live"
      assert html =~ "Coming Soon"
    end

    test "shows effective status badges", %{conn: conn} do
      Tools.create_tool(Map.put(@tool_attrs, :admin_enabled, false))

      {:ok, _lv, html} = live(conn, ~p"/admin/tools")
      assert html =~ "Maintenance"
    end

    test "shows tool URLs", %{conn: conn} do
      Tools.create_tool(Map.put(@tool_attrs, :url, "https://pulse.oostkit.com"))

      {:ok, _lv, html} = live(conn, ~p"/admin/tools")
      assert html =~ "https://pulse.oostkit.com"
    end
  end

  describe "toggle admin_enabled" do
    setup :register_and_log_in_super_admin

    test "disables an enabled tool", %{conn: conn} do
      Tools.create_tool(@tool_attrs)

      {:ok, lv, html} = live(conn, ~p"/admin/tools")
      assert html =~ ~s|aria-checked="true"|

      lv
      |> element(~s|button[phx-click="toggle_enabled"][phx-value-id="test_tool"]|)
      |> render_click()

      html = render(lv)
      assert html =~ "Test Tool disabled."
      assert html =~ "Maintenance"
    end

    test "enables a disabled tool", %{conn: conn} do
      Tools.create_tool(Map.put(@tool_attrs, :admin_enabled, false))

      {:ok, lv, html} = live(conn, ~p"/admin/tools")
      assert html =~ ~s|aria-checked="false"|

      lv
      |> element(~s|button[phx-click="toggle_enabled"][phx-value-id="test_tool"]|)
      |> render_click()

      html = render(lv)
      assert html =~ "Test Tool enabled."
    end
  end
end
