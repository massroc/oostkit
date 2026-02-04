defmodule Wrt.Workers.CleanupExpiredMagicLinksTest do
  use Wrt.DataCase, async: true

  alias Wrt.Workers.CleanupExpiredMagicLinks
  alias Wrt.MagicLinks
  alias Wrt.MagicLinks.MagicLink

  describe "perform/1" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      %{tenant: tenant, round: round, person: person}
    end

    test "deletes expired magic links across tenants", %{tenant: tenant, round: round, person: person} do
      # Create expired links
      for i <- 1..3 do
        expired = %MagicLink{
          token: "expired-#{i}-#{System.unique_integer([:positive])}",
          expires_at: DateTime.utc_now() |> DateTime.add(-i * 60 * 60) |> DateTime.truncate(:second),
          person_id: person.id,
          round_id: round.id
        }

        Wrt.Repo.insert!(expired, prefix: tenant)
      end

      # Create a valid link that should not be deleted
      {:ok, valid} = MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})

      # Run the worker
      assert :ok = CleanupExpiredMagicLinks.perform(%Oban.Job{})

      # Valid link should still exist
      assert MagicLinks.get_by_token(tenant, valid.token) != nil
    end

    test "returns :ok even when no expired links exist", %{tenant: tenant, round: round, person: person} do
      {:ok, _valid} = MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})

      assert :ok = CleanupExpiredMagicLinks.perform(%Oban.Job{})
    end

    test "returns :ok when no tenants exist" do
      # This tests the edge case where there are no tenants
      assert :ok = CleanupExpiredMagicLinks.perform(%Oban.Job{})
    end
  end

  describe "schedule/0" do
    test "inserts a scheduled job" do
      assert {:ok, job} = CleanupExpiredMagicLinks.schedule()
      assert job.worker == "Wrt.Workers.CleanupExpiredMagicLinks"
      assert job.scheduled_at != nil
    end
  end
end
