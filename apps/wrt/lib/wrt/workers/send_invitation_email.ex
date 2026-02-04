defmodule Wrt.Workers.SendInvitationEmail do
  @moduledoc """
  Oban worker for sending individual invitation emails.

  This worker is queued for each contact when a round starts.
  It creates a magic link and sends the invitation email.
  """

  use Oban.Worker, queue: :emails, max_attempts: 3

  alias Wrt.Emails
  alias Wrt.MagicLinks
  alias Wrt.Platform
  alias Wrt.Rounds
  alias Wrt.Rounds.Contact

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"tenant" => tenant, "contact_id" => contact_id, "org_id" => org_id}
      }) do
    with {:ok, contact} <- get_contact(tenant, contact_id),
         {:ok, org} <- get_org(org_id),
         {:ok, magic_link} <- get_or_create_magic_link(tenant, contact),
         {:ok, _email} <- send_email(contact, magic_link, org),
         {:ok, _contact} <- mark_invited(tenant, contact) do
      Logger.info(
        "Sent invitation email to #{contact.person.email} for round #{contact.round_id}"
      )

      :ok
    else
      {:error, reason} ->
        Logger.error(
          "Failed to send invitation email for contact #{contact_id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp get_contact(tenant, contact_id) do
    case Rounds.get_contact(tenant, contact_id) do
      nil -> {:error, :contact_not_found}
      contact -> {:ok, contact}
    end
  end

  defp get_org(org_id) do
    case Platform.get_organisation(org_id) do
      nil -> {:error, :org_not_found}
      org -> {:ok, org}
    end
  end

  defp get_or_create_magic_link(tenant, contact) do
    MagicLinks.get_or_create_magic_link(tenant, contact.person_id, contact.round_id)
  end

  defp send_email(contact, magic_link, org) do
    case Emails.send_invitation(contact, magic_link, org) do
      {:ok, _} -> {:ok, :sent}
      {:error, reason} -> {:error, {:email_send_failed, reason}}
    end
  end

  defp mark_invited(tenant, contact) do
    contact
    |> Contact.invite_changeset()
    |> Wrt.Repo.update(prefix: tenant)
  end
end
