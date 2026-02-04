defmodule Wrt.Workers.SendVerificationCode do
  @moduledoc """
  Oban worker for sending verification code emails.

  This is used when a nominator requests a code to verify their identity.
  """

  use Oban.Worker, queue: :emails, max_attempts: 3

  alias Wrt.Emails
  alias Wrt.MagicLinks
  alias Wrt.Platform

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"tenant" => tenant, "magic_link_id" => magic_link_id, "org_id" => org_id}
      }) do
    with {:ok, magic_link} <- get_magic_link(tenant, magic_link_id),
         {:ok, org} <- get_org(org_id),
         {:ok, _email} <- send_email(magic_link, org) do
      Logger.info("Sent verification code to #{magic_link.person.email}")
      :ok
    else
      {:error, reason} ->
        Logger.error(
          "Failed to send verification code for magic_link #{magic_link_id}: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp get_magic_link(tenant, magic_link_id) do
    case MagicLinks.get_magic_link(tenant, magic_link_id) do
      nil -> {:error, :magic_link_not_found}
      magic_link -> {:ok, magic_link}
    end
  end

  defp get_org(org_id) do
    case Platform.get_organisation(org_id) do
      nil -> {:error, :org_not_found}
      org -> {:ok, org}
    end
  end

  defp send_email(magic_link, org) do
    case Emails.send_verification_code(magic_link, org) do
      {:ok, _} -> {:ok, :sent}
      {:error, reason} -> {:error, {:email_send_failed, reason}}
    end
  end

  @doc """
  Enqueues the job to send a verification code.
  """
  def enqueue(tenant, magic_link_id, org_id) do
    %{tenant: tenant, magic_link_id: magic_link_id, org_id: org_id}
    |> new()
    |> Oban.insert()
  end
end
