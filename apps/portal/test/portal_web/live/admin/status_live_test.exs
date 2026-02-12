defmodule PortalWeb.Admin.StatusLiveTest do
  use PortalWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Portal.AccountsFixtures

  alias Portal.StatusPoller

  setup do
    # Start the StatusPoller without polling (avoid real HTTP calls in tests)
    start_supervised!({StatusPoller, [poll_interval: :timer.hours(1), poll_on_init: false]})
    :ok
  end

  describe "authorization" do
    test "unauthenticated user redirects to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/status")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "session manager redirects to /", %{conn: conn} do
      session_manager = session_manager_fixture()

      assert {:error, redirect} =
               conn
               |> log_in_user(session_manager)
               |> live(~p"/admin/status")

      assert {:redirect, %{to: "/", flash: flash}} = redirect
      assert %{"error" => "You must be a super admin to access this page."} = flash
    end
  end

  describe "status page" do
    setup :register_and_log_in_super_admin

    test "renders system status page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/status")

      assert html =~ "System Status"
      assert html =~ "App Health"
      assert html =~ "CI Status"
      assert html =~ "Auto-refreshes every 5 minutes"
    end

    test "shows waiting message when no data yet", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/status")

      assert html =~ "Waiting for first health check"
      assert html =~ "Waiting for first CI status check"
    end

    test "refresh button triggers new poll", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/status")

      html = lv |> element("button", "Refresh now") |> render_click()
      assert html =~ "System Status"
    end

    test "updates on PubSub broadcast", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/status")

      Phoenix.PubSub.broadcast(Portal.PubSub, "status_updates", {:status_update, %{
        health: %{
          "Portal" => %{healthy: true, status: 200, response_time_ms: 42, checked_at: DateTime.utc_now()},
          "Pulse" => %{healthy: true, status: 200, response_time_ms: 55, checked_at: DateTime.utc_now()},
          "WRT" => %{healthy: false, status: nil, error: "timeout", checked_at: DateTime.utc_now()}
        },
        ci: %{
          "Portal" => [%{conclusion: "success", status: "completed", created_at: "2026-02-13T12:00:00Z", html_url: "https://github.com/rossm/oostkit/actions/runs/1", head_sha: "abc1234"}],
          "Pulse" => [],
          "WRT" => [%{conclusion: "failure", status: "completed", created_at: "2026-02-13T11:00:00Z", html_url: "https://github.com/rossm/oostkit/actions/runs/2", head_sha: "def5678"}]
        },
        last_polled: DateTime.utc_now()
      }})

      html = render(lv)
      assert html =~ "42ms"
      assert html =~ "55ms"
      assert html =~ "timeout"
      assert html =~ "Passed"
      assert html =~ "Failed"
    end
  end
end
