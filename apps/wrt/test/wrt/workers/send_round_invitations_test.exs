defmodule Wrt.Workers.SendRoundInvitationsTest do
  use Wrt.DataCase, async: true

  alias Wrt.Workers.SendRoundInvitations

  setup do
    tenant = create_test_tenant()
    org = Repo.insert!(build(:approved_organisation))
    campaign = insert_in_tenant(tenant, :active_campaign)

    round =
      insert_in_tenant(tenant, :active_round, %{
        campaign_id: campaign.id,
        round_number: 1
      })

    %{tenant: tenant, org: org, campaign: campaign, round: round}
  end

  describe "perform/1" do
    test "queues invitation emails for each contact in round", %{
      tenant: tenant,
      org: org,
      round: round
    } do
      person1 = insert_in_tenant(tenant, :person)
      person2 = insert_in_tenant(tenant, :person)
      insert_in_tenant(tenant, :contact, %{person_id: person1.id, round_id: round.id})
      insert_in_tenant(tenant, :contact, %{person_id: person2.id, round_id: round.id})

      job = %Oban.Job{
        args: %{
          "tenant" => tenant,
          "round_id" => round.id,
          "org_id" => org.id
        }
      }

      assert :ok = SendRoundInvitations.perform(job)
    end

    test "returns :ok with no contacts", %{tenant: tenant, org: org, round: round} do
      job = %Oban.Job{
        args: %{
          "tenant" => tenant,
          "round_id" => round.id,
          "org_id" => org.id
        }
      }

      assert :ok = SendRoundInvitations.perform(job)
    end
  end

  describe "enqueue/3" do
    test "inserts an Oban job", %{tenant: tenant, org: org, round: round} do
      assert {:ok, job} = SendRoundInvitations.enqueue(tenant, round.id, org.id)
      assert job.worker == "Wrt.Workers.SendRoundInvitations"
      assert job.args["tenant"] == tenant
      assert job.args["round_id"] == round.id
      assert job.args["org_id"] == org.id
    end
  end
end
