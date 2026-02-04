defmodule Wrt.Workers.SendRoundInvitations do
  @moduledoc """
  Oban worker for queueing all invitation emails for a round.

  This worker is called when a round starts. It creates individual
  SendInvitationEmail jobs for each contact in the round.
  """

  use Oban.Worker, queue: :rounds, max_attempts: 1

  alias Wrt.Rounds
  alias Wrt.Workers.SendInvitationEmail

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tenant" => tenant, "round_id" => round_id, "org_id" => org_id}}) do
    contacts = Rounds.list_contacts(tenant, round_id)

    Logger.info("Queueing #{length(contacts)} invitation emails for round #{round_id}")

    jobs =
      Enum.map(contacts, fn contact ->
        SendInvitationEmail.new(%{
          tenant: tenant,
          contact_id: contact.id,
          org_id: org_id
        })
      end)

    Oban.insert_all(jobs)

    :ok
  end

  @doc """
  Enqueues the job to send invitations for a round.
  """
  def enqueue(tenant, round_id, org_id) do
    %{tenant: tenant, round_id: round_id, org_id: org_id}
    |> new()
    |> Oban.insert()
  end
end
