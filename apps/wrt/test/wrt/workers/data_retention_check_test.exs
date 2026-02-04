defmodule Wrt.Workers.DataRetentionCheckTest do
  use Wrt.DataCase, async: true

  alias Wrt.Workers.DataRetentionCheck

  describe "perform/1 with check action" do
    test "returns :ok for check action" do
      job = %Oban.Job{args: %{"action" => "check"}}
      assert :ok = DataRetentionCheck.perform(job)
    end

    test "returns :ok when no args provided (defaults to check)" do
      job = %Oban.Job{args: %{}}
      assert :ok = DataRetentionCheck.perform(job)
    end
  end

  describe "perform/1 with warn action" do
    test "returns :ok for warn action even without valid org" do
      job = %Oban.Job{
        args: %{
          "action" => "warn",
          "org_id" => -1,
          "campaign_ids" => []
        }
      }

      assert :ok = DataRetentionCheck.perform(job)
    end
  end

  describe "perform/1 with archive action" do
    test "returns :ok for archive action with empty campaign list" do
      job = %Oban.Job{
        args: %{
          "action" => "archive",
          "tenant" => "tenant_999",
          "campaign_ids" => []
        }
      }

      assert :ok = DataRetentionCheck.perform(job)
    end
  end

  describe "perform/1 with unknown action" do
    test "returns error for unknown action" do
      job = %Oban.Job{args: %{"action" => "invalid_action"}}
      assert {:error, :unknown_action} = DataRetentionCheck.perform(job)
    end
  end

  describe "schedule/0" do
    test "inserts a scheduled job" do
      assert {:ok, job} = DataRetentionCheck.schedule()
      assert job.worker == "Wrt.Workers.DataRetentionCheck"
      assert job.scheduled_at != nil
    end
  end
end
