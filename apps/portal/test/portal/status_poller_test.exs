defmodule Portal.StatusPollerTest do
  use ExUnit.Case, async: true

  alias Portal.StatusPoller

  @no_poll [poll_interval: :timer.hours(1), poll_on_init: false]

  def mock_health do
    %{
      "Portal" => %{
        status: 200,
        healthy: true,
        response_time_ms: 10,
        checked_at: DateTime.utc_now()
      },
      "Pulse" => %{
        status: 200,
        healthy: true,
        response_time_ms: 15,
        checked_at: DateTime.utc_now()
      },
      "WRT" => %{status: 200, healthy: true, response_time_ms: 12, checked_at: DateTime.utc_now()}
    }
  end

  def mock_ci do
    %{
      "Portal" => [
        %{
          conclusion: "success",
          status: "completed",
          created_at: "2026-01-01T00:00:00Z",
          html_url: "https://example.com",
          head_sha: "abc1234"
        }
      ],
      "Pulse" => [
        %{
          conclusion: "success",
          status: "completed",
          created_at: "2026-01-01T00:00:00Z",
          html_url: "https://example.com",
          head_sha: "def5678"
        }
      ],
      "WRT" => []
    }
  end

  @mock_poll [
    poll_interval: :timer.hours(1),
    poll_on_init: false,
    health_check_fn: &Portal.StatusPollerTest.mock_health/0,
    ci_check_fn: &Portal.StatusPollerTest.mock_ci/0
  ]

  describe "start_link/1" do
    test "starts and returns empty initial state when poll_on_init is false" do
      start_supervised!({StatusPoller, @no_poll})

      status = StatusPoller.get_status()
      assert status.health == %{}
      assert status.ci == %{}
      assert status.last_polled == nil
    end
  end

  describe "get_status/0" do
    test "returns health, ci, and last_polled keys" do
      start_supervised!({StatusPoller, @no_poll})

      status = StatusPoller.get_status()
      assert Map.has_key?(status, :health)
      assert Map.has_key?(status, :ci)
      assert Map.has_key?(status, :last_polled)
    end
  end

  describe "subscribe/0 and refresh/0" do
    test "receives status_update messages after refresh" do
      start_supervised!({StatusPoller, @mock_poll})

      StatusPoller.subscribe()
      StatusPoller.refresh()

      assert_receive {:status_update, status}, 5_000
      assert is_map(status.health)
      assert is_map(status.ci)
      assert %DateTime{} = status.last_polled
    end
  end

  describe "poll cycle" do
    test "poll populates state with health and ci data" do
      start_supervised!({StatusPoller, @mock_poll})

      # Trigger a poll manually
      send(Process.whereis(StatusPoller), :poll)

      # Mock functions return instantly, small sleep for GenServer to process
      Process.sleep(100)

      status = StatusPoller.get_status()
      assert %DateTime{} = status.last_polled
      assert map_size(status.health) == 3
      assert status.health["Portal"].healthy == true
      assert map_size(status.ci) == 3
    end
  end
end
