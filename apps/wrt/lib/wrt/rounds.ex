defmodule Wrt.Rounds do
  @moduledoc """
  The Rounds context.

  Handles round management within a campaign, including:
  - Round lifecycle (pending → active → closed)
  - Contact tracking (who has been invited)
  - Single-ask constraint enforcement
  """

  import Ecto.Query, warn: false
  alias Wrt.Repo
  alias Wrt.Rounds.{Round, Contact}
  alias Wrt.People

  # =============================================================================
  # Round Functions
  # =============================================================================

  @doc """
  Lists all rounds for a campaign.
  """
  def list_rounds(tenant, campaign_id) do
    Round
    |> where([r], r.campaign_id == ^campaign_id)
    |> order_by([r], asc: r.round_number)
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Gets the active round for a campaign (if any).
  """
  def get_active_round(tenant, campaign_id) do
    Round
    |> where([r], r.campaign_id == ^campaign_id and r.status == "active")
    |> Repo.one(prefix: tenant)
  end

  @doc """
  Gets a round by ID.
  """
  def get_round(tenant, id) do
    Repo.get(Round, id, prefix: tenant)
  end

  @doc """
  Gets a round by ID, raising if not found.
  """
  def get_round!(tenant, id) do
    Repo.get!(Round, id, prefix: tenant)
  end

  @doc """
  Gets a round by campaign and round number.
  """
  def get_round_by_number(tenant, campaign_id, round_number) do
    Round
    |> where([r], r.campaign_id == ^campaign_id and r.round_number == ^round_number)
    |> Repo.one(prefix: tenant)
  end

  @doc """
  Gets the next round number for a campaign.
  """
  def next_round_number(tenant, campaign_id) do
    Round
    |> where([r], r.campaign_id == ^campaign_id)
    |> select([r], max(r.round_number))
    |> Repo.one(prefix: tenant)
    |> case do
      nil -> 1
      n -> n + 1
    end
  end

  @doc """
  Creates a new round for a campaign.
  """
  def create_round(tenant, campaign_id, attrs \\ %{}) do
    round_number = next_round_number(tenant, campaign_id)

    attrs =
      Map.merge(attrs, %{
        campaign_id: campaign_id,
        round_number: round_number
      })

    %Round{}
    |> Round.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Starts a round.

  This will:
  1. Mark the round as active
  2. Create contacts for eligible people (not previously contacted)
  3. For round 1, contact seed group; for subsequent rounds, contact nominees from previous round
  """
  def start_round(tenant, %Round{} = round, duration_days) do
    deadline =
      DateTime.utc_now()
      |> DateTime.add(duration_days * 24 * 60 * 60, :second)
      |> DateTime.truncate(:second)

    Repo.transaction(fn ->
      # Start the round
      {:ok, round} =
        round
        |> Round.start_changeset(deadline)
        |> Repo.update(prefix: tenant)

      # Create contacts for eligible people
      eligible_people = get_eligible_people(tenant, round)

      contacts =
        Enum.map(eligible_people, fn person ->
          {:ok, contact} = create_contact(tenant, %{person_id: person.id, round_id: round.id})
          contact
        end)

      {round, contacts}
    end)
  end

  @doc """
  Closes a round.
  """
  def close_round(tenant, %Round{} = round) do
    if Round.active?(round) do
      round
      |> Round.close_changeset()
      |> Repo.update(prefix: tenant)
    else
      {:error, :round_not_active}
    end
  end

  @doc """
  Extends a round deadline.
  """
  def extend_round(tenant, %Round{} = round, new_deadline) do
    if Round.active?(round) do
      round
      |> Round.extend_changeset(new_deadline)
      |> Repo.update(prefix: tenant)
    else
      {:error, :round_not_active}
    end
  end

  # =============================================================================
  # Contact Functions
  # =============================================================================

  @doc """
  Creates a contact record.
  """
  def create_contact(tenant, attrs) do
    %Contact{}
    |> Contact.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Gets a contact by ID.
  """
  def get_contact(tenant, id) do
    Contact
    |> Repo.get(id, prefix: tenant)
    |> Repo.preload([:person, :round], prefix: tenant)
  end

  @doc """
  Gets a contact for a person in a round.
  """
  def get_contact_for_person(tenant, round_id, person_id) do
    Contact
    |> where([c], c.round_id == ^round_id and c.person_id == ^person_id)
    |> Repo.one(prefix: tenant)
  end

  @doc """
  Lists contacts for a round.
  """
  def list_contacts(tenant, round_id) do
    Contact
    |> where([c], c.round_id == ^round_id)
    |> preload([:person])
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Lists contacts that haven't responded yet.
  """
  def list_pending_contacts(tenant, round_id) do
    Contact
    |> where([c], c.round_id == ^round_id and is_nil(c.responded_at))
    |> preload([:person])
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Marks a contact as having responded.
  """
  def mark_responded(tenant, %Contact{} = contact) do
    contact
    |> Contact.respond_changeset()
    |> Repo.update(prefix: tenant)
  end

  @doc """
  Updates contact email status (for webhook tracking).
  """
  def update_email_status(tenant, contact_id, status) do
    timestamp_field =
      case status do
        "delivered" -> :delivered_at
        "opened" -> :opened_at
        "clicked" -> :clicked_at
        _ -> nil
      end

    contact = Repo.get(Contact, contact_id, prefix: tenant)

    cond do
      is_nil(contact) ->
        {:error, :not_found}

      timestamp_field ->
        contact
        |> Contact.email_status_changeset(status, timestamp_field)
        |> Repo.update(prefix: tenant)

      status in ["bounced", "spam"] ->
        # For bounced/spam, just update the status without a timestamp
        contact
        |> Ecto.Changeset.change(%{email_status: status})
        |> Repo.update(prefix: tenant)

      true ->
        {:error, :invalid_status}
    end
  end

  @doc """
  Counts contacts by response status for a round.
  """
  def count_contacts(tenant, round_id) do
    total =
      Contact
      |> where([c], c.round_id == ^round_id)
      |> Repo.aggregate(:count, prefix: tenant)

    responded =
      Contact
      |> where([c], c.round_id == ^round_id and not is_nil(c.responded_at))
      |> Repo.aggregate(:count, prefix: tenant)

    %{total: total, responded: responded, pending: total - responded}
  end

  # =============================================================================
  # Single-Ask Constraint
  # =============================================================================

  @doc """
  Gets people eligible for contact in a round.

  For round 1: seed group (people with source = "seed")
  For subsequent rounds: nominees from previous round who haven't been contacted yet

  The single-ask constraint means anyone who has been contacted in ANY round
  is excluded from future rounds.
  """
  def get_eligible_people(tenant, %Round{round_number: 1, campaign_id: campaign_id}) do
    # First round: seed group only
    previously_contacted = get_all_contacted_person_ids(tenant, campaign_id)

    People.list_seed_people(tenant)
    |> Enum.reject(fn person -> person.id in previously_contacted end)
  end

  def get_eligible_people(tenant, %Round{round_number: round_number, campaign_id: campaign_id}) do
    # Subsequent rounds: nominees from previous round
    previous_round = get_round_by_number(tenant, campaign_id, round_number - 1)

    if previous_round do
      previously_contacted = get_all_contacted_person_ids(tenant, campaign_id)

      # Get all nominees from the previous round
      People.list_nominations_for_round(tenant, previous_round.id)
      |> Enum.map(& &1.nominee)
      |> Enum.uniq_by(& &1.id)
      |> Enum.reject(fn person -> person.id in previously_contacted end)
    else
      []
    end
  end

  @doc """
  Gets all person IDs that have been contacted in any round of a campaign.
  """
  def get_all_contacted_person_ids(tenant, campaign_id) do
    Contact
    |> join(:inner, [c], r in Round, on: c.round_id == r.id)
    |> where([c, r], r.campaign_id == ^campaign_id)
    |> select([c], c.person_id)
    |> Repo.all(prefix: tenant)
    |> MapSet.new()
  end

  @doc """
  Checks if a person has been contacted in any round of a campaign.
  """
  def person_contacted?(tenant, campaign_id, person_id) do
    Contact
    |> join(:inner, [c], r in Round, on: c.round_id == r.id)
    |> where([c, r], r.campaign_id == ^campaign_id and c.person_id == ^person_id)
    |> Repo.exists?(prefix: tenant)
  end
end
