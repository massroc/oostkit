defmodule PortalWeb.PageControllerTest do
  use PortalWeb.ConnCase

  alias Portal.Tools

  setup do
    {:ok, _} =
      Tools.create_tool(%{
        id: "workgroup_pulse",
        name: "Workgroup Pulse",
        tagline: "6 Criteria for Productive Work",
        description: "Test tool for teams",
        url: "https://pulse.oostkit.com",
        audience: "team",
        default_status: "live",
        sort_order: 1
      })

    {:ok, _} =
      Tools.create_tool(%{
        id: "wrt",
        name: "Workshop Referral Tool",
        tagline: "Participative selection for design workshops",
        audience: "facilitator",
        default_status: "coming_soon",
        sort_order: 2
      })

    :ok
  end

  describe "GET / (landing page)" do
    test "renders the marketing landing page for anonymous users", %{conn: conn} do
      conn = get(conn, ~p"/")

      assert html_response(conn, 200) =~ "Tools for building democratic workplaces"
      assert html_response(conn, 200) =~ "Try Workgroup Pulse"
      assert html_response(conn, 200) =~ "Explore all tools"
      assert html_response(conn, 200) =~ "Built on Open Systems Theory"
    end

    test "redirects logged-in users to /home", %{conn: conn} do
      %{conn: conn} = register_and_log_in_user(%{conn: conn})

      conn = get(conn, ~p"/")
      assert redirected_to(conn) == ~p"/home"
    end
  end

  describe "GET /home (dashboard)" do
    test "renders tool cards from database", %{conn: conn} do
      conn = get(conn, ~p"/home")

      assert html_response(conn, 200) =~ "Your tools"
      assert html_response(conn, 200) =~ "Workgroup Pulse"
      assert html_response(conn, 200) =~ "Workshop Referral Tool"
    end

    test "shows Launch button for live tools", %{conn: conn} do
      conn = get(conn, ~p"/home")

      assert html_response(conn, 200) =~ "Launch"
      assert html_response(conn, 200) =~ "pulse.oostkit.com"
    end

    test "shows Coming soon badge for coming_soon tools", %{conn: conn} do
      conn = get(conn, ~p"/home")

      assert html_response(conn, 200) =~ "Coming soon"
    end
  end

  describe "GET /home onboarding card" do
    test "shows onboarding card for logged-in user who hasn't completed onboarding", %{
      conn: conn
    } do
      %{conn: conn} = register_and_log_in_user(%{conn: conn})
      conn = get(conn, ~p"/home")

      assert html_response(conn, 200) =~ "Tell us a bit about yourself"
      assert html_response(conn, 200) =~ "Organisation"
      assert html_response(conn, 200) =~ "Skip for now"
    end

    test "hides onboarding card for anonymous users", %{conn: conn} do
      conn = get(conn, ~p"/home")

      refute html_response(conn, 200) =~ "Tell us a bit about yourself"
    end

    test "hides onboarding card after onboarding is completed", %{conn: conn} do
      %{conn: conn, user: user} = register_and_log_in_user(%{conn: conn})
      Portal.Accounts.skip_onboarding(user)
      conn = get(conn, ~p"/home")

      refute html_response(conn, 200) =~ "Tell us a bit about yourself"
    end
  end

  describe "GET /apps/:app_id" do
    test "renders app detail page for valid tool", %{conn: conn} do
      conn = get(conn, ~p"/apps/workgroup_pulse")

      assert html_response(conn, 200) =~ "Workgroup Pulse"
      assert html_response(conn, 200) =~ "6 Criteria for Productive Work"
      assert html_response(conn, 200) =~ "Launch"
    end

    test "renders coming soon state for coming_soon tool", %{conn: conn} do
      conn = get(conn, ~p"/apps/wrt")

      assert html_response(conn, 200) =~ "Workshop Referral Tool"
      assert html_response(conn, 200) =~ "coming soon"
    end

    test "redirects to home for invalid app", %{conn: conn} do
      conn = get(conn, ~p"/apps/nonexistent")

      assert redirected_to(conn) == ~p"/home"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Application not found"
    end
  end
end
