defmodule Wrt.Workers.SendInvitationEmailTest do
  use Wrt.DataCase, async: true

  alias Wrt.Workers.SendInvitationEmail

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
      insert_in_tenant(tenant, :contact, %{
        person_id: person.id,
        round_id: round.id
      })

    %{tenant: tenant, org: org, round: round, person: person, contact: contact}
  end

  describe "perform/1" do
    test "sends invitation email and marks contact as invited", %{
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

      assert :ok = SendInvitationEmail.perform(job)

      # Verify contact was marked as invited
      updated_contact = Wrt.Rounds.get_contact(tenant, contact.id)
      assert updated_contact.email_status == "sent"
      assert updated_contact.invited_at != nil
    end

    test "returns error for non-existent contact", %{tenant: tenant, org: org} do
      job = %Oban.Job{
        args: %{
          "tenant" => tenant,
          "contact_id" => -1,
          "org_id" => org.id
        }
      }

      assert {:error, :contact_not_found} = SendInvitationEmail.perform(job)
    end

    test "returns error for non-existent org", %{tenant: tenant, contact: contact} do
      job = %Oban.Job{
        args: %{
          "tenant" => tenant,
          "contact_id" => contact.id,
          "org_id" => -1
        }
      }

      assert {:error, :org_not_found} = SendInvitationEmail.perform(job)
    end
  end
end
