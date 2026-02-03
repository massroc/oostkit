defmodule ProductiveWorkgroups.Sessions do
  @moduledoc """
  The Sessions context.

  This context manages workshop sessions and their participants.
  It handles session lifecycle, participant management, state transitions,
  and turn-based scoring flow.

  ## Turn-Based Scoring

  During the scoring phase, participants score one at a time in join order:
  - Use `get_participants_in_turn_order/1` to get the scoring order
  - Use `get_current_turn_participant/1` to get whose turn it is
  - Use `advance_turn/1` when a participant clicks "Done"
  - Use `skip_turn/1` to skip a participant who is away
  """

  import Ecto.Query, warn: false

  alias ProductiveWorkgroups.Repo
  alias ProductiveWorkgroups.Sessions.{Participant, Session}
  alias ProductiveWorkgroups.Timestamps
  alias ProductiveWorkgroups.Workshops.Template

  @pubsub ProductiveWorkgroups.PubSub

  ## PubSub Helpers

  @doc """
  Returns the PubSub topic for a session.
  """
  def session_topic(%Session{id: id}), do: "session:#{id}"
  def session_topic(session_id) when is_binary(session_id), do: "session:#{session_id}"

  @doc """
  Subscribes to session updates.
  """
  def subscribe(%Session{} = session) do
    Phoenix.PubSub.subscribe(@pubsub, session_topic(session))
  end

  defp broadcast(%Session{} = session, event) do
    Phoenix.PubSub.broadcast(@pubsub, session_topic(session), event)
    :ok
  end

  ## Session Code Generation

  @code_chars ~c"ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
  @code_length 6

  @doc """
  Generates a unique session code.

  Codes are alphanumeric, uppercase, and avoid ambiguous characters
  (0/O, 1/I/L) for easier reading and sharing.
  """
  def generate_code do
    for _ <- 1..@code_length, into: "" do
      <<Enum.random(@code_chars)>>
    end
  end

  ## Sessions

  @doc """
  Creates a new session for the given template.

  ## Options

  - `:planned_duration_minutes` - Optional planned duration
  - `:settings` - Optional map of session settings
  """
  def create_session(%Template{} = template, attrs \\ %{}) do
    code = generate_unique_code()

    # Normalize attrs to string keys for consistency with form params
    normalized_attrs =
      attrs
      |> Enum.map(fn
        {k, v} when is_atom(k) -> {Atom.to_string(k), v}
        {k, v} -> {k, v}
      end)
      |> Map.new()
      |> Map.put("code", code)

    %Session{}
    |> Session.create_changeset(template, normalized_attrs)
    |> Repo.insert()
  end

  defp generate_unique_code do
    code = generate_code()

    if get_session_by_code(code) do
      generate_unique_code()
    else
      code
    end
  end

  @doc """
  Gets a single session.

  Raises `Ecto.NoResultsError` if the Session does not exist.
  """
  def get_session!(id) do
    Session
    |> Repo.get!(id)
    |> Repo.preload([:template, :participants])
  end

  @doc """
  Gets a session by its code.

  The lookup is case-insensitive.
  Returns nil if no session is found.
  """
  def get_session_by_code(code) when is_binary(code) do
    normalized_code = String.upcase(code)
    Repo.get_by(Session, code: normalized_code)
  end

  @doc """
  Gets a session with participants preloaded.
  """
  def get_session_with_participants(id) do
    Session
    |> Repo.get!(id)
    |> Repo.preload(:participants)
  end

  @doc """
  Gets a session with template and participants preloaded.
  """
  def get_session_with_all(id) do
    Session
    |> Repo.get!(id)
    |> Repo.preload([:template, :participants])
  end

  ## Session State Transitions

  @doc """
  Starts a session, transitioning from lobby to intro.
  """
  def start_session(%Session{state: "lobby"} = session) do
    session
    |> Session.transition_changeset("intro", %{
      started_at: Timestamps.now()
    })
    |> Repo.update()
    |> with_broadcast(fn s -> broadcast(s, {:session_started, s}) end)
  end

  @doc """
  Advances from intro to scoring phase.

  Resets turn tracking for the first question.
  """
  def advance_to_scoring(%Session{state: "intro"} = session) do
    result =
      session
      |> Session.transition_changeset("scoring", %{
        current_question_index: 0,
        current_turn_index: 0
      })
      |> Repo.update()

    broadcast_session_update(result)
  end

  @doc """
  Advances to the next question within the scoring phase.

  Resets turn tracking for the new question and locks the previous row.
  """
  def advance_question(%Session{state: "scoring"} = session) do
    # Lock all scores for the current question before advancing
    ProductiveWorkgroups.Scoring.lock_row(session, session.current_question_index)

    # Reset all participants' ready state for the new question
    reset_all_ready(session)

    result =
      session
      |> Session.transition_changeset("scoring", %{
        current_question_index: session.current_question_index + 1,
        current_turn_index: 0
      })
      |> Repo.update()

    # Broadcast participants_reset so clients refresh their participant data
    broadcast(session, {:participants_ready_reset, %{}})

    broadcast_session_update(result)
  end

  @doc """
  Advances from scoring to summary phase.
  """
  def advance_to_summary(%Session{state: "scoring"} = session) do
    result =
      session
      |> Session.transition_changeset("summary")
      |> Repo.update()

    broadcast_session_update(result)
  end

  @doc """
  Advances from summary to actions phase.
  """
  def advance_to_actions(%Session{state: "summary"} = session) do
    result =
      session
      |> Session.transition_changeset("actions")
      |> Repo.update()

    broadcast_session_update(result)
  end

  @doc """
  Advances from summary directly to completed state (wrap-up page).
  """
  def advance_to_completed(%Session{state: "summary"} = session) do
    result =
      session
      |> Session.transition_changeset("completed", %{
        completed_at: Timestamps.now()
      })
      |> Repo.update()

    broadcast_session_update(result)
  end

  @doc """
  Completes the session.
  """
  def complete_session(%Session{state: "actions"} = session) do
    result =
      session
      |> Session.transition_changeset("completed", %{
        completed_at: Timestamps.now()
      })
      |> Repo.update()

    broadcast_session_update(result)
  end

  ## Backward Navigation

  @doc """
  Goes back to the previous question within the scoring phase.

  Returns `{:error, :at_first_question}` if already at question 0.
  """
  def go_back_question(%Session{state: "scoring", current_question_index: 0}) do
    {:error, :at_first_question}
  end

  def go_back_question(%Session{state: "scoring"} = session) do
    result =
      session
      |> Session.transition_changeset("scoring", %{
        current_question_index: session.current_question_index - 1
      })
      |> Repo.update()

    broadcast_session_update(result)
  end

  @doc """
  Goes back from scoring (at question 0) to intro.
  """
  def go_back_to_intro(%Session{state: "scoring", current_question_index: 0} = session) do
    result =
      session
      |> Session.transition_changeset("intro", %{current_question_index: 0})
      |> Repo.update()

    broadcast_session_update(result)
  end

  @doc """
  Goes back from summary to the last scoring question.
  """
  def go_back_to_scoring(%Session{state: "summary"} = session, last_question_index) do
    result =
      session
      |> Session.transition_changeset("scoring", %{current_question_index: last_question_index})
      |> Repo.update()

    broadcast_session_update(result)
  end

  @doc """
  Goes back from actions or completed (wrap-up) to summary.
  """
  def go_back_to_summary(%Session{state: state} = session)
      when state in ["actions", "completed"] do
    result =
      session
      |> Session.transition_changeset("summary")
      |> Repo.update()

    broadcast_session_update(result)
  end

  defp broadcast_session_update({:ok, session}) do
    broadcast(session, {:session_updated, session})
    {:ok, session}
  end

  defp broadcast_session_update(error), do: error

  # Helper for broadcasting on success
  defp with_broadcast({:ok, session} = result, broadcast_fn) do
    broadcast_fn.(session)
    result
  end

  defp with_broadcast(error, _broadcast_fn), do: error

  @doc """
  Updates the last_activity_at timestamp for the session.
  """
  def touch_session(%Session{} = session) do
    session
    |> Ecto.Changeset.change(last_activity_at: Timestamps.now())
    |> Repo.update()
  end

  ## Participants

  @doc """
  Joins a participant to a session.

  If a participant with the same browser_token already exists,
  their name is updated and they are returned.

  ## Options

  - `:is_facilitator` - Set to true if this participant is the facilitator
  """
  def join_session(%Session{} = session, name, browser_token, opts \\ []) do
    is_facilitator = Keyword.get(opts, :is_facilitator, false)
    is_observer = Keyword.get(opts, :is_observer, false)

    case get_participant(session, browser_token) do
      nil ->
        create_new_participant(session, name, browser_token, is_facilitator, is_observer)

      existing ->
        update_existing_participant(session, existing, name)
    end
  end

  defp create_new_participant(session, name, browser_token, is_facilitator, is_observer) do
    if name_taken?(session, name) do
      {:error, :name_taken}
    else
      result =
        %Participant{}
        |> Participant.join_changeset(session, %{
          name: name,
          browser_token: browser_token,
          is_facilitator: is_facilitator,
          is_observer: is_observer
        })
        |> Repo.insert()

      case result do
        {:ok, participant} ->
          broadcast(session, {:participant_joined, participant})
          {:ok, participant}

        error ->
          error
      end
    end
  end

  defp update_existing_participant(session, existing, name) do
    if name != existing.name and name_taken?(session, name) do
      {:error, :name_taken}
    else
      existing
      |> Participant.changeset(%{
        name: name,
        last_seen_at: Timestamps.now()
      })
      |> Repo.update()
    end
  end

  defp name_taken?(%Session{} = session, name) do
    Participant
    |> where([p], p.session_id == ^session.id)
    |> where([p], fragment("LOWER(?) = LOWER(?)", p.name, ^name))
    |> Repo.exists?()
  end

  @doc """
  Gets the facilitator of a session.
  """
  def get_facilitator(%Session{} = session) do
    Participant
    |> where([p], p.session_id == ^session.id and p.is_facilitator == true)
    |> Repo.one()
  end

  @doc """
  Gets a participant by their browser token.
  """
  def get_participant(%Session{} = session, browser_token) do
    Repo.get_by(Participant, session_id: session.id, browser_token: browser_token)
  end

  @doc """
  Lists all participants in a session.
  """
  def list_participants(%Session{} = session) do
    Participant
    |> where([p], p.session_id == ^session.id)
    |> order_by([p], [p.joined_at, p.id])
    |> Repo.all()
  end

  @doc """
  Lists only active participants in a session.
  """
  def list_active_participants(%Session{} = session) do
    Participant
    |> where([p], p.session_id == ^session.id and p.status == "active")
    |> order_by([p], [p.joined_at, p.id])
    |> Repo.all()
  end

  @doc """
  Counts participants in a session.
  """
  def count_participants(%Session{} = session) do
    Participant
    |> where([p], p.session_id == ^session.id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Updates a participant's status.
  """
  def update_participant_status(%Participant{} = participant, status) do
    result =
      participant
      |> Participant.status_changeset(status)
      |> Repo.update()

    case result do
      {:ok, updated} ->
        session = Repo.get!(Session, participant.session_id)

        if status == "dropped" do
          broadcast(session, {:participant_left, updated.id})
        else
          broadcast(session, {:participant_updated, updated})
        end

        {:ok, updated}

      error ->
        error
    end
  end

  @doc """
  Sets a participant's ready state.
  """
  def set_participant_ready(%Participant{} = participant, is_ready) do
    result =
      participant
      |> Participant.ready_changeset(is_ready)
      |> Repo.update()

    case result do
      {:ok, updated} ->
        session = Repo.get!(Session, participant.session_id)
        broadcast(session, {:participant_ready, updated})
        {:ok, updated}

      error ->
        error
    end
  end

  @doc """
  Resets all participants' ready state to false.
  """
  def reset_all_ready(%Session{} = session) do
    Participant
    |> where([p], p.session_id == ^session.id)
    |> Repo.update_all(set: [is_ready: false])

    :ok
  end

  @doc """
  Checks if all active participants are ready.
  """
  def all_participants_ready?(%Session{} = session) do
    active_count =
      Participant
      |> where([p], p.session_id == ^session.id and p.status == "active")
      |> Repo.aggregate(:count)

    ready_count =
      Participant
      |> where([p], p.session_id == ^session.id and p.status == "active" and p.is_ready == true)
      |> Repo.aggregate(:count)

    active_count > 0 and active_count == ready_count
  end

  ## Turn-Based Scoring

  @doc """
  Gets participants in turn order (by join time).

  Only returns active, non-observer participants who can score.
  """
  def get_participants_in_turn_order(%Session{} = session) do
    Participant
    |> where([p], p.session_id == ^session.id)
    |> where([p], p.status == "active")
    |> where([p], p.is_observer == false)
    |> order_by([p], asc: p.joined_at, asc: p.id)
    |> Repo.all()
  end

  @doc """
  Gets the participant whose turn it currently is.

  Returns nil if there's no current turn participant (e.g., all turns complete).
  """
  def get_current_turn_participant(%Session{} = session) do
    participants = get_participants_in_turn_order(session)
    Enum.at(participants, session.current_turn_index)
  end

  @doc """
  Checks if it's a specific participant's turn to score.
  """
  def participants_turn?(%Session{} = session, %Participant{} = participant) do
    current = get_current_turn_participant(session)
    current != nil and current.id == participant.id
  end

  @doc """
  Checks if all turns are complete for the current question.

  Returns true when all participants have either scored or been skipped.
  """
  def all_turns_complete?(%Session{} = session) do
    participants = get_participants_in_turn_order(session)
    session.current_turn_index >= length(participants)
  end

  @doc """
  Advances to the next participant's turn.

  Returns the updated session. When all participants have had their turn
  (either scored or skipped), marks all turns as complete.
  """
  def advance_turn(%Session{state: "scoring"} = session) do
    participants = get_participants_in_turn_order(session)
    next_index = session.current_turn_index + 1

    if next_index < length(participants) do
      # More participants to go in normal order
      advance_to_next_participant(session, next_index)
    else
      # All active participants have had their turn
      handle_round_complete(session)
    end
  end

  defp advance_to_next_participant(session, next_index) do
    session
    |> Session.transition_changeset("scoring", %{current_turn_index: next_index})
    |> Repo.update()
    |> with_broadcast(&broadcast_turn_advanced/1)
  end

  defp handle_round_complete(session) do
    # All participants have had their turn (either scored or skipped)
    # Mark all turns complete by setting current_turn_index past the end
    # This signals that scoring input is done and discussion can begin
    participants = get_participants_in_turn_order(session)

    session
    |> Session.transition_changeset("scoring", %{current_turn_index: length(participants)})
    |> Repo.update()
    |> with_broadcast(&broadcast_turn_advanced/1)
  end

  @doc """
  Skips the current participant and advances to the next.

  Use when a participant is away or disconnected.
  """
  def skip_turn(%Session{state: "scoring"} = session) do
    advance_turn(session)
  end

  @doc """
  Gets participants who were skipped (have no score for the given question).
  """
  def get_skipped_participants(%Session{} = session, question_index) do
    participants = get_participants_in_turn_order(session)
    scores = ProductiveWorkgroups.Scoring.list_scores_for_question(session, question_index)
    scored_participant_ids = MapSet.new(Enum.map(scores, & &1.participant_id))

    Enum.filter(participants, fn p ->
      not MapSet.member?(scored_participant_ids, p.id)
    end)
  end

  # Private helpers for turn-based broadcasting

  defp broadcast_turn_advanced(%Session{} = session) do
    current_participant = get_current_turn_participant(session)

    broadcast(
      session,
      {:turn_advanced,
       %{
         current_turn_index: session.current_turn_index,
         current_participant_id: current_participant && current_participant.id
       }}
    )
  end
end
