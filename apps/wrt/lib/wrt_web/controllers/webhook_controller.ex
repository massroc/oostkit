defmodule WrtWeb.WebhookController do
  @moduledoc """
  Handles webhooks from email providers (Postmark, SendGrid).

  Tracks email delivery events and updates contact records with:
  - delivered_at: Email was successfully delivered
  - opened_at: Recipient opened the email
  - clicked_at: Recipient clicked a link in the email

  Webhook payloads contain metadata with tenant and contact_id to identify
  which contact record to update.
  """
  use WrtWeb, :controller

  alias Wrt.Rounds

  require Logger

  @doc """
  Handles email webhook events from various providers.
  """
  def email(conn, %{"provider" => provider} = params) do
    case provider do
      "postmark" -> handle_postmark(conn, params)
      "sendgrid" -> handle_sendgrid(conn, params)
      _ -> handle_unknown_provider(conn, provider)
    end
  end

  # Postmark webhook handler
  # See: https://postmarkapp.com/developer/webhooks/webhooks-overview
  defp handle_postmark(conn, params) do
    record_type = params["RecordType"]
    metadata = params["Metadata"] || %{}

    tenant = metadata["tenant"]
    contact_id = metadata["contact_id"]

    cond do
      is_nil(tenant) or is_nil(contact_id) ->
        Logger.warning("Postmark webhook missing metadata: #{inspect(metadata)}")
        json(conn, %{status: "ignored", reason: "missing_metadata"})

      is_nil(postmark_record_type_to_status(record_type)) ->
        json(conn, %{status: "ignored", reason: "unknown_record_type"})

      true ->
        process_postmark_status(conn, tenant, contact_id, postmark_record_type_to_status(record_type))
    end
  end

  defp process_postmark_status(conn, tenant, contact_id, status) do
    case Rounds.update_email_status(tenant, contact_id, status) do
      {:ok, _contact} ->
        Logger.info("Updated contact #{contact_id} with status: #{status}")
        json(conn, %{status: "processed"})

      {:error, reason} ->
        Logger.warning("Failed to update contact #{contact_id}: #{inspect(reason)}")
        json(conn, %{status: "error", reason: "update_failed"})
    end
  end

  # SendGrid webhook handler
  # See: https://docs.sendgrid.com/for-developers/tracking-events/event
  defp handle_sendgrid(conn, %{"_json" => events}) when is_list(events) do
    # SendGrid sends an array of events
    results =
      Enum.map(events, fn event ->
        process_sendgrid_event(event)
      end)

    successful = Enum.count(results, &(&1 == :ok))
    json(conn, %{status: "processed", count: successful})
  end

  defp handle_sendgrid(conn, params) do
    # Single event format
    case process_sendgrid_event(params) do
      :ok -> json(conn, %{status: "processed"})
      :ignored -> json(conn, %{status: "ignored"})
      :error -> json(conn, %{status: "error"})
    end
  end

  defp process_sendgrid_event(event) do
    event_type = event["event"]
    # SendGrid uses custom_args for metadata
    tenant = event["tenant"]
    contact_id = event["contact_id"]
    status = sendgrid_event_to_status(event_type)

    cond do
      is_nil(tenant) or is_nil(contact_id) -> :ignored
      is_nil(status) -> :ignored
      true -> do_update_sendgrid_status(tenant, contact_id, status)
    end
  end

  defp do_update_sendgrid_status(tenant, contact_id, status) do
    case Rounds.update_email_status(tenant, contact_id, status) do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
  end

  defp handle_unknown_provider(conn, provider) do
    Logger.warning("Unknown webhook provider: #{provider}")

    conn
    |> put_status(:bad_request)
    |> json(%{status: "error", reason: "unknown_provider"})
  end

  # Map Postmark record types to our status values
  defp postmark_record_type_to_status(record_type) do
    case record_type do
      "Delivery" -> "delivered"
      "Open" -> "opened"
      "Click" -> "clicked"
      "Bounce" -> "bounced"
      "SpamComplaint" -> "spam"
      _ -> nil
    end
  end

  # Map SendGrid events to our status values
  defp sendgrid_event_to_status(event) do
    case event do
      "delivered" -> "delivered"
      "open" -> "opened"
      "click" -> "clicked"
      "bounce" -> "bounced"
      "spamreport" -> "spam"
      _ -> nil
    end
  end
end
