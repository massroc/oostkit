defmodule Wrt.Workers.SendReminderEmailTest do
  use Wrt.DataCase, async: true

  alias Wrt.Workers.SendReminderEmail

  setup do
    tenant = create_test_tenant()
    org = Repo.insert!(build(:approved_organisation))
    campaign = insert_in_tenant(tenant, :active_campaign)

    round =
      insert_in_tenant(tenant, :active_round, %{
        campaign_id: campaign.id,
        round_number: 1
      })

    person = insert_in_tenant(tenant, :person)

    contact =
      insert_in_tenant(tenant, :invited_contact, %{
        person_id: person.id,
        round_id: round.id
      })

    %{tenant: tenant, org: org, round: round, person: person, contact: contact}
  end

  describe "perform/1" do
    test "sends reminder email to contact who hasn't responded", %{
      tenant: tenant,
      org: org,
      contact: contact
    } do
      job = %Oban.Job{
        args: %{
          "tenant" => tenant,
          "contact_id" => contact.id,
          "org_id" => org.id
        }
      }

      assert :ok = SendReminderEmail.perform(job)
    end

    test "skips sending if contact already responded", %{
      tenant: tenant,
      org: org,
      round: round
    } do
      responded_person = insert_in_tenant(tenant, :person)

      responded_contact =
        insert_in_tenant(tenant, :responded_contact, %{
          person_id: responded_person.id,
          round_id: round.id
        })

      job = %Oban.Job{
        args: %{
          "tenant" => tenant,
          "contact_id" => responded_contact.id,
          "org_id" => org.id
        }
      }

      # Should return :ok without sending (skipped)
      assert :ok = SendReminderEmail.perform(job)
    end

    test "returns error for non-existent contact", %{tenant: tenant, org: org} do
      job = %Oban.Job{
        args: %{
          "tenant" => tenant,
          "contact_id" => -1,
          "org_id" => org.id
        }
      }

      assert {:error, :contact_not_found} = SendReminderEmail.perform(job)
    end

    test "returns error for non-existent org", %{tenant: tenant, contact: contact} do
      job = %Oban.Job{
        args: %{
          "tenant" => tenant,
          "contact_id" => contact.id,
          "org_id" => -1
        }
      }

      assert {:error, :org_not_found} = SendReminderEmail.perform(job)
    end
  end
end
