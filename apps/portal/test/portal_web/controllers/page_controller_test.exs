defmodule PortalWeb.PageControllerTest do
  use PortalWeb.ConnCase

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

    test "renders category headings", %{conn: conn} do
      conn = get(conn, ~p"/home")
      html = html_response(conn, 200)

      assert html =~ "Learning"
      assert html =~ "Workshop Management"
      assert html =~ "Team Workshops"
    end

    test "shows Launch button for live tools", %{conn: conn} do
      conn = get(conn, ~p"/home")

      assert html_response(conn, 200) =~ "Launch"
      assert html_response(conn, 200) =~ "localhost:4000"
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

    test "renders inline email capture for coming_soon tool", %{conn: conn} do
      conn = get(conn, ~p"/apps/wrt")

      html = html_response(conn, 200)
      assert html =~ "Workshop Referral Tool"
      assert html =~ "Notify me"
      assert html =~ "notify_email"
    end

    test "shows success state after subscribing", %{conn: conn} do
      conn = get(conn, ~p"/apps/wrt?subscribed=true")

      html = html_response(conn, 200)
      assert html =~ "let you know when"
      refute html =~ "Notify me"
    end

    test "includes Open Graph meta tags", %{conn: conn} do
      conn = get(conn, ~p"/apps/workgroup_pulse")

      html = html_response(conn, 200)
      assert html =~ ~s(property="og:title")
      assert html =~ ~s(property="og:description")
    end

    test "redirects to home for invalid app", %{conn: conn} do
      conn = get(conn, ~p"/apps/nonexistent")

      assert redirected_to(conn) == ~p"/home"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Application not found"
    end
  end

  describe "POST /apps/:app_id/notify" do
    test "creates interest signup and redirects with subscribed flag", %{conn: conn} do
      conn =
        post(conn, ~p"/apps/wrt/notify", %{
          "signup" => %{"name" => "Test", "email" => "test@example.com"}
        })

      assert redirected_to(conn) == "/apps/wrt?subscribed=true"

      signups = Portal.Marketing.list_interest_signups()
      assert length(signups) == 1
      assert hd(signups).context == "tool:wrt"
      assert hd(signups).email == "test@example.com"
    end

    test "redirects with error for invalid email", %{conn: conn} do
      conn =
        post(conn, ~p"/apps/wrt/notify", %{
          "signup" => %{"name" => "Test", "email" => ""}
        })

      assert redirected_to(conn) == "/apps/wrt"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "valid email"
    end

    test "redirects to home for invalid app", %{conn: conn} do
      conn =
        post(conn, ~p"/apps/nonexistent/notify", %{
          "signup" => %{"email" => "test@example.com"}
        })

      assert redirected_to(conn) == ~p"/home"
    end
  end
end
