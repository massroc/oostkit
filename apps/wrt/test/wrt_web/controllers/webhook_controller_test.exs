defmodule WrtWeb.WebhookControllerTest do
  use WrtWeb.ConnCase, async: true

  alias Wrt.Rounds.Contact

  describe "POST /webhooks/email/postmark" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      contact =
        Wrt.Repo.insert!(
          %Contact{
            person_id: person.id,
            round_id: round.id,
            email_status: "sent",
            invited_at: now
          },
          prefix: tenant
        )

      %{tenant: tenant, contact: contact}
    end

    test "processes Delivery event and updates contact status", %{
      conn: conn,
      tenant: tenant,
      contact: contact
    } do
      payload = %{
        "RecordType" => "Delivery",
        "Metadata" => %{
          "tenant" => tenant,
          "contact_id" => to_string(contact.id)
        }
      }

      conn = post(conn, "/webhooks/email/postmark", payload)

      assert json_response(conn, 200)["status"] == "processed"

      # Verify contact was updated
      updated = Wrt.Repo.get!(Contact, contact.id, prefix: tenant)
      assert updated.email_status == "delivered"
      assert updated.delivered_at != nil
    end

    test "processes Open event", %{conn: conn, tenant: tenant, contact: contact} do
      payload = %{
        "RecordType" => "Open",
        "Metadata" => %{
          "tenant" => tenant,
          "contact_id" => to_string(contact.id)
        }
      }

      conn = post(conn, "/webhooks/email/postmark", payload)

      assert json_response(conn, 200)["status"] == "processed"
    end

    test "processes Click event", %{conn: conn, tenant: tenant, contact: contact} do
      payload = %{
        "RecordType" => "Click",
        "Metadata" => %{
          "tenant" => tenant,
          "contact_id" => to_string(contact.id)
        }
      }

      conn = post(conn, "/webhooks/email/postmark", payload)

      assert json_response(conn, 200)["status"] == "processed"
    end

    test "ignores unknown record types", %{conn: conn, tenant: tenant, contact: contact} do
      payload = %{
        "RecordType" => "UnknownType",
        "Metadata" => %{
          "tenant" => tenant,
          "contact_id" => to_string(contact.id)
        }
      }

      conn = post(conn, "/webhooks/email/postmark", payload)

      assert json_response(conn, 200)["status"] == "ignored"
      assert json_response(conn, 200)["reason"] == "unknown_record_type"
    end

    test "ignores events without metadata", %{conn: conn} do
      payload = %{
        "RecordType" => "Delivery"
      }

      conn = post(conn, "/webhooks/email/postmark", payload)

      assert json_response(conn, 200)["status"] == "ignored"
      assert json_response(conn, 200)["reason"] == "missing_metadata"
    end

    test "ignores events with incomplete metadata", %{conn: conn, tenant: tenant} do
      payload = %{
        "RecordType" => "Delivery",
        "Metadata" => %{
          "tenant" => tenant
          # missing contact_id
        }
      }

      conn = post(conn, "/webhooks/email/postmark", payload)

      assert json_response(conn, 200)["status"] == "ignored"
      assert json_response(conn, 200)["reason"] == "missing_metadata"
    end
  end

  describe "POST /webhooks/email/sendgrid" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      contact =
        Wrt.Repo.insert!(
          %Contact{
            person_id: person.id,
            round_id: round.id,
            email_status: "sent",
            invited_at: now
          },
          prefix: tenant
        )

      %{tenant: tenant, contact: contact}
    end

    test "processes single delivered event", %{conn: conn, tenant: tenant, contact: contact} do
      payload = %{
        "event" => "delivered",
        "tenant" => tenant,
        "contact_id" => to_string(contact.id)
      }

      conn = post(conn, "/webhooks/email/sendgrid", payload)

      assert json_response(conn, 200)["status"] == "processed"
    end

    test "processes batch of events", %{conn: conn, tenant: tenant, contact: contact} do
      # SendGrid sends events as an array under "_json" key
      payload = %{
        "_json" => [
          %{
            "event" => "delivered",
            "tenant" => tenant,
            "contact_id" => to_string(contact.id)
          },
          %{
            "event" => "open",
            "tenant" => tenant,
            "contact_id" => to_string(contact.id)
          }
        ]
      }

      conn = post(conn, "/webhooks/email/sendgrid", payload)

      response = json_response(conn, 200)
      assert response["status"] == "processed"
      assert response["count"] >= 0
    end

    test "processes open event", %{conn: conn, tenant: tenant, contact: contact} do
      payload = %{
        "event" => "open",
        "tenant" => tenant,
        "contact_id" => to_string(contact.id)
      }

      conn = post(conn, "/webhooks/email/sendgrid", payload)

      assert json_response(conn, 200)["status"] == "processed"
    end

    test "processes click event", %{conn: conn, tenant: tenant, contact: contact} do
      payload = %{
        "event" => "click",
        "tenant" => tenant,
        "contact_id" => to_string(contact.id)
      }

      conn = post(conn, "/webhooks/email/sendgrid", payload)

      assert json_response(conn, 200)["status"] == "processed"
    end

    test "ignores events without tenant", %{conn: conn, contact: contact} do
      payload = %{
        "event" => "delivered",
        "contact_id" => to_string(contact.id)
      }

      conn = post(conn, "/webhooks/email/sendgrid", payload)

      assert json_response(conn, 200)["status"] == "ignored"
    end

    test "ignores unknown event types", %{conn: conn, tenant: tenant, contact: contact} do
      payload = %{
        "event" => "unknown_event",
        "tenant" => tenant,
        "contact_id" => to_string(contact.id)
      }

      conn = post(conn, "/webhooks/email/sendgrid", payload)

      assert json_response(conn, 200)["status"] == "ignored"
    end
  end

  describe "POST /webhooks/email/:provider with unknown provider" do
    test "returns 400 for unknown provider", %{conn: conn} do
      conn = post(conn, "/webhooks/email/unknown", %{})

      assert json_response(conn, 400)["status"] == "error"
      assert json_response(conn, 400)["reason"] == "unknown_provider"
    end
  end
end
