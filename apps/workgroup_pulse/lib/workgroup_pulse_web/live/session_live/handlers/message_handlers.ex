defmodule WorkgroupPulseWeb.SessionLive.Handlers.MessageHandlers do
  @moduledoc """
  Handlers for PubSub messages (handle_info callbacks) in the session LiveView.
  """

  import Phoenix.Component, only: [assign: 2]
  import Phoenix.LiveView, only: [put_flash: 3]

  alias WorkgroupPulse.Sessions
  alias WorkgroupPulseWeb.SessionLive.Helpers.DataLoaders
  alias WorkgroupPulseWeb.SessionLive.Helpers.StateHelpers

  @doc """
  Handles participant_joined message.
  Adds participant to list if not already present.
  """
  def handle_participant_joined(socket, participant) do
    participants = socket.assigns.participants

    if Enum.any?(participants, &(&1.id == participant.id)) do
      socket
    else
      assign(socket, participants: participants ++ [participant])
    end
  end

  @doc """
  Handles participant_left message.
  Removes participant from list.
  """
  def handle_participant_left(socket, participant_id) do
    participants =
      Enum.reject(socket.assigns.participants, fn p -> p.id == participant_id end)

    assign(socket, participants: participants)
  end

  @doc """
  Handles participant_updated message.
  Updates participant in list.
  """
  def handle_participant_updated(socket, participant) do
    participants =
      Enum.map(socket.assigns.participants, fn p ->
        if p.id == participant.id, do: participant, else: p
      end)

    assign(socket, participants: participants)
  end

  @doc """
  Handles participant_ready message.
  Updates participant ready state in list and recalculates readiness counts.
  """
  def handle_participant_ready(socket, participant) do
    alias WorkgroupPulse.Scoring

    participants =
      Enum.map(socket.assigns.participants, fn p ->
        if p.id == participant.id, do: participant, else: p
      end)

    # Update participants first
    socket = assign(socket, participants: participants)

    # Build score map from all_scores to check who actually scored (not skipped)
    # Only include participants who have state :scored (not :skipped, :pending, :current)
    all_scores = socket.assigns[:all_scores] || []

    score_map =
      all_scores
      |> Enum.filter(fn s -> s.state == :scored end)
      |> Map.new(fn s -> {s.participant_id, s} end)

    # Check if all turns are done and if row is locked (revisiting completed question)
    session = socket.assigns.session
    all_turns_done = Sessions.all_turns_complete?(session)
    row_locked = Scoring.row_locked?(session, session.current_question_index)

    # Recalculate readiness counts for non-facilitator, non-observer participants
    eligible_participants =
      Enum.filter(participants, fn p ->
        p.status == "active" and not p.is_facilitator and not p.is_observer
      end)

    eligible_count = length(eligible_participants)

    # If row is locked, we're revisiting a completed question - everyone is auto-ready
    {ready_count, all_ready} =
      if row_locked do
        {eligible_count, true}
      else
        # Ready if: clicked ready, or was skipped (no score when all turns done)
        # Note: Having a score does NOT count as ready - participants must explicitly
        # click "I'm Ready to Continue" after team discussion
        ready_count =
          Enum.count(eligible_participants, fn p ->
            was_skipped = all_turns_done and not Map.has_key?(score_map, p.id)
            p.is_ready or was_skipped
          end)

        # When no eligible participants (only facilitator/observers), consider all ready
        all_ready = eligible_count == 0 or ready_count == eligible_count
        {ready_count, all_ready}
      end

    socket
    |> assign(ready_count: ready_count)
    |> assign(eligible_participant_count: eligible_count)
    |> assign(all_ready: all_ready)
  end

  @doc """
  Handles participants_ready_reset message.
  Resets all participants' ready state to false for a new question.
  """
  def handle_participants_ready_reset(socket) do
    participants =
      Enum.map(socket.assigns.participants, fn p ->
        %{p | is_ready: false}
      end)

    # Also reset the individual participant assign
    participant = %{socket.assigns.participant | is_ready: false}

    socket
    |> assign(participant: participant)
    |> assign(participants: participants)
    |> assign(ready_count: 0)
    |> assign(all_ready: false)
  end

  @doc """
  Handles session_started message.
  Updates session and handles state transition.
  """
  def handle_session_started(socket, session) do
    old_session = socket.assigns.session

    socket
    |> assign(session: session)
    |> StateHelpers.handle_state_transition(old_session, session)
  end

  @doc """
  Handles session_updated message.
  Updates session and handles state transition.
  """
  def handle_session_updated(socket, session) do
    old_session = socket.assigns.session

    socket
    |> assign(session: session)
    |> StateHelpers.handle_state_transition(old_session, session)
  end

  @doc """
  Handles score_submitted message from other participants.
  Reloads scores if in scoring state for the relevant question.
  """
  def handle_score_submitted(socket, _participant_id, question_index) do
    session = socket.assigns.session

    if session.state == "scoring" and session.current_question_index == question_index do
      template = socket.assigns[:template]

      socket
      |> DataLoaders.load_scores(session, question_index)
      |> DataLoaders.load_all_questions_scores(session, template)
    else
      socket
    end
  end

  @doc """
  Handles note_updated message from other participants.
  Reloads notes if in scoring state for the relevant question.
  """
  def handle_note_updated(socket, question_index) do
    session = socket.assigns.session

    if session.state == "scoring" and session.current_question_index == question_index do
      DataLoaders.load_notes(socket, session, question_index)
    else
      socket
    end
  end

  @doc """
  Handles action_updated message from other participants.
  Reloads actions if in a state that shows actions.
  """
  def handle_action_updated(socket, _action_id) do
    session = socket.assigns.session

    if session.state in ["summary", "actions", "completed"] do
      DataLoaders.load_actions_data(socket, session)
    else
      socket
    end
  end

  @doc """
  Handles flash message from child components.
  """
  def handle_flash(socket, kind, message) do
    put_flash(socket, kind, message)
  end

  @doc """
  Handles reload_actions message from ActionFormComponent.
  """
  def handle_reload_actions(socket) do
    DataLoaders.load_actions_data(socket, socket.assigns.session)
  end

  @doc """
  Handles turn_advanced message in turn-based scoring.
  Reloads session and scoring data.
  """
  def handle_turn_advanced(socket, _payload) do
    updated_session = Sessions.get_session!(socket.assigns.session.id)
    participant = socket.assigns.participant

    socket
    |> assign(session: updated_session)
    |> DataLoaders.load_scoring_data(updated_session, participant)
  end

  @doc """
  Handles row_locked message when group advances to next question.
  Reloads scores for current question.
  """
  def handle_row_locked(socket, _payload) do
    session = socket.assigns.session
    DataLoaders.load_scores(socket, session, session.current_question_index)
  end
end
