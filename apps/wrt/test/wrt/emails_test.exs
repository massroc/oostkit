defmodule Wrt.EmailsTest do
  use Wrt.DataCase, async: true

  alias Wrt.Emails

  setup do
    tenant = create_test_tenant()
    campaign = insert_in_tenant(tenant, :campaign, %{name: "Test Campaign"})

    round =
      insert_in_tenant(tenant, :active_round, %{
        campaign_id: campaign.id,
        round_number: 1,
        deadline:
          DateTime.utc_now() |> DateTime.add(7 * 24 * 60 * 60) |> DateTime.truncate(:second)
      })

    person = insert_in_tenant(tenant, :person, %{name: "Alice Test", email: "alice@example.com"})

    contact =
      insert_in_tenant(tenant, :contact, %{
        person_id: person.id,
        round_id: round.id
      })

    contact = Repo.preload(contact, [:person, :round], prefix: tenant)

    org = Repo.insert!(build(:approved_organisation, %{name: "Test Org"}))

    magic_link =
      insert_in_tenant(tenant, :magic_link_with_code, %{
        person_id: person.id,
        round_id: round.id
      })

    magic_link = Repo.preload(magic_link, [:person, :round], prefix: tenant)

    %{
      tenant: tenant,
      campaign: campaign,
      round: round,
      person: person,
      contact: contact,
      org: org,
      magic_link: magic_link
    }
  end

  describe "invitation_email/3" do
    test "composes invitation email with correct fields", %{
      contact: contact,
      magic_link: magic_link,
      org: org
    } do
      email = Emails.invitation_email(contact, magic_link, org)

      assert email.to == [{"Alice Test", "alice@example.com"}]
      assert email.subject =~ "invited to participate"
      assert email.subject =~ org.name
      assert email.html_body =~ "Alice Test"
      assert email.html_body =~ "Submit Your Nominations"
      assert email.text_body =~ "Alice Test"
      assert email.text_body =~ magic_link.token
    end
  end

  describe "send_invitation/3" do
    test "delivers invitation email", %{contact: contact, magic_link: magic_link, org: org} do
      assert {:ok, _} = Emails.send_invitation(contact, magic_link, org)
    end
  end

  describe "verification_code_email/2" do
    test "composes verification code email with correct fields", %{
      magic_link: magic_link,
      org: org
    } do
      email = Emails.verification_code_email(magic_link, org)

      assert email.to == [{"Alice Test", "alice@example.com"}]
      assert email.subject =~ "verification code"
      assert email.html_body =~ magic_link.code
      assert email.text_body =~ magic_link.code
    end
  end

  describe "send_verification_code/2" do
    test "delivers verification code email", %{magic_link: magic_link, org: org} do
      assert {:ok, _} = Emails.send_verification_code(magic_link, org)
    end
  end

  describe "reminder_email/3" do
    test "composes reminder email with correct fields", %{
      contact: contact,
      magic_link: magic_link,
      org: org
    } do
      email = Emails.reminder_email(contact, magic_link, org)

      assert email.to == [{"Alice Test", "alice@example.com"}]
      assert email.subject =~ "Reminder"
      assert email.subject =~ org.name
      assert email.html_body =~ "Alice Test"
      assert email.html_body =~ "Submit Your Nominations Now"
      assert email.text_body =~ "Alice Test"
    end
  end

  describe "send_reminder/3" do
    test "delivers reminder email", %{contact: contact, magic_link: magic_link, org: org} do
      assert {:ok, _} = Emails.send_reminder(contact, magic_link, org)
    end
  end

  describe "retention_warning_email/3" do
    test "composes retention warning email with correct fields", %{campaign: campaign} do
      email = Emails.retention_warning_email("admin@example.com", campaign, 30)

      assert email.to == [{"", "admin@example.com"}]
      assert email.subject =~ "Data Retention Notice"
      assert email.subject =~ campaign.name
      assert email.html_body =~ campaign.name
      assert email.html_body =~ "30"
      assert email.text_body =~ campaign.name
      assert email.text_body =~ "30"
    end

    test "includes deletion date in email body", %{campaign: campaign} do
      email = Emails.retention_warning_email("admin@example.com", campaign, 15)

      expected_date =
        Date.utc_today()
        |> Date.add(15)
        |> Calendar.strftime("%B %d, %Y")

      assert email.html_body =~ expected_date
      assert email.text_body =~ expected_date
    end
  end

  describe "send_retention_warning/3" do
    test "delivers retention warning email", %{campaign: campaign} do
      assert {:ok, _} = Emails.send_retention_warning("admin@example.com", campaign, 30)
    end
  end
end
