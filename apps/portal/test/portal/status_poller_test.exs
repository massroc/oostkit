defmodule Portal.StatusPollerTest do
  use ExUnit.Case, async: true

  alias Portal.StatusPoller

  @no_poll [poll_interval: :timer.hours(1), poll_on_init: false]

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
      start_supervised!({StatusPoller, @no_poll})

      StatusPoller.subscribe()
      StatusPoller.refresh()

      assert_receive {:status_update, status}, 30_000
      assert is_map(status.health)
      assert is_map(status.ci)
      assert %DateTime{} = status.last_polled
    end
  end

  describe "poll cycle" do
    test "poll populates state with health and ci data" do
      start_supervised!({StatusPoller, @no_poll})

      # Trigger a poll manually
      send(Process.whereis(StatusPoller), :poll)

      # Wait for the poll to complete (health checks may take a few seconds)
      Process.sleep(15_000)

      status = StatusPoller.get_status()
      assert %DateTime{} = status.last_polled
      # Health checks will have entries even if they fail
      assert map_size(status.health) == 3
    end
  end
end
