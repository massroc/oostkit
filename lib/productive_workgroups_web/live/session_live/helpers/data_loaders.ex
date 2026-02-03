defmodule ProductiveWorkgroupsWeb.SessionLive.Helpers.DataLoaders do
  @moduledoc """
  Data loading functions for the session LiveView.
  Handles loading scoring data, summary data, notes, and actions.
  """

  import Phoenix.Component, only: [assign: 2]
  import ProductiveWorkgroupsWeb.SessionLive.ScoreHelpers

  alias ProductiveWorkgroups.Notes
  alias ProductiveWorkgroups.Scoring
  alias ProductiveWorkgroups.Sessions
  alias ProductiveWorkgroups.Workshops

  @doc """
  Loads scoring data for the current question when in scoring state.
  """
  def load_scoring_data(socket, %{state: "scoring"} = session, participant) do
    # Reuse cached template to avoid repeated database queries
    template = get_or_load_template(socket, session.template_id)
    question_index = session.current_question_index
    question = Enum.find(template.questions, &(&1.index == question_index))

    my_score = Scoring.get_score(session, participant, question_index)
    current_turn_participant = Sessions.get_current_turn_participant(session)

    # Calculate turn-based state
    turn_state =
      calculate_turn_state(
        session,
        participant,
        my_score,
        current_turn_participant,
        question_index
      )

    socket
    |> assign(template: template)
    |> assign(total_questions: length(template.questions))
    |> assign(current_question: question)
    |> assign(selected_value: if(my_score, do: my_score.value, else: nil))
    |> assign(my_score: if(my_score, do: my_score.value, else: nil))
    |> assign(has_submitted: my_score != nil)
    |> assign(my_turn_locked: turn_state.my_turn_locked)
    |> assign(is_my_turn: turn_state.is_my_turn)
    |> assign(current_turn_participant_id: turn_state.current_turn_participant_id)
    |> assign(current_turn_has_score: turn_state.current_turn_has_score)
    |> assign(participant_was_skipped: turn_state.participant_was_skipped)
    |> assign(show_facilitator_tips: false)
    |> assign(show_notes: false)
    |> load_scores(session, question_index)
    |> load_notes(session, question_index)
  end

  def load_scoring_data(socket, _session, _participant) do
    reset_scoring_assigns(socket)
  end

  defp calculate_turn_state(
         session,
         participant,
         my_score,
         current_turn_participant,
         question_index
       ) do
    my_turn_locked = my_score != nil and my_score.turn_locked

    is_my_turn =
      current_turn_participant != nil and
        current_turn_participant.id == participant.id and
        not participant.is_observer

    current_turn_has_score =
      current_turn_participant != nil and
        Scoring.get_score(session, current_turn_participant, question_index) != nil

    all_turns_done = Sessions.all_turns_complete?(session)
    participant_was_skipped = all_turns_done and my_score == nil and not participant.is_observer

    %{
      my_turn_locked: my_turn_locked,
      is_my_turn: is_my_turn,
      current_turn_participant_id: current_turn_participant && current_turn_participant.id,
      current_turn_has_score: current_turn_has_score,
      participant_was_skipped: participant_was_skipped
    }
  end

  @doc """
  Resets all scoring-related assigns to default values.
  """
  def reset_scoring_assigns(socket) do
    socket
    |> assign(template: nil)
    |> assign(total_questions: 0)
    |> assign(current_question: nil)
    |> assign(selected_value: nil)
    |> assign(my_score: nil)
    |> assign(has_submitted: false)
    |> assign(my_turn_locked: false)
    |> assign(is_my_turn: false)
    |> assign(current_turn_participant_id: nil)
    |> assign(current_turn_has_score: false)
    |> assign(participant_was_skipped: false)
    |> assign(all_scores: [])
    |> assign(scores_revealed: false)
    |> assign(score_count: 0)
    |> assign(active_participant_count: 0)
    |> assign(question_notes: [])
    |> assign(show_facilitator_tips: false)
    |> assign(show_notes: false)
    |> assign(ready_count: 0)
    |> assign(eligible_participant_count: 0)
    |> assign(all_ready: false)
  end

  @doc """
  Loads scores for a specific question and builds participant score grid.
  """
  def load_scores(socket, session, question_index) do
    scores = Scoring.list_scores_for_question(session, question_index)
    # Show results when all turns are complete (everyone has either scored or been skipped)
    all_turns_done = Sessions.all_turns_complete?(session)
    all_scored = all_turns_done or Scoring.all_scored?(session, question_index)

    # Get participants in turn order (active, non-observers)
    participants_in_turn_order = Sessions.get_participants_in_turn_order(session)
    active_count = length(participants_in_turn_order)

    # Build score map for O(1) lookups: participant_id => score
    score_map = Map.new(scores, &{&1.participant_id, &1})

    # Build full participant grid showing all participants with their states
    participant_scores =
      build_participant_scores(
        participants_in_turn_order,
        score_map,
        session,
        socket.assigns[:current_question]
      )

    # Check if current turn participant has submitted a score (for messaging)
    current_turn_participant = Enum.at(participants_in_turn_order, session.current_turn_index)

    current_turn_has_score =
      current_turn_participant != nil and Map.has_key?(score_map, current_turn_participant.id)

    # Calculate readiness for non-facilitator, non-observer participants
    # Skipped participants (no score when all turns done) count as ready
    {ready_count, eligible_count, all_ready} =
      calculate_readiness(socket.assigns[:participants] || [], score_map, all_turns_done)

    socket
    |> assign(all_scores: participant_scores)
    |> assign(scores_revealed: all_scored)
    |> assign(score_count: length(scores))
    |> assign(active_participant_count: active_count)
    |> assign(current_turn_has_score: current_turn_has_score)
    |> assign(ready_count: ready_count)
    |> assign(eligible_participant_count: eligible_count)
    |> assign(all_ready: all_ready)
  end

  defp build_participant_scores(participants, score_map, session, current_question) do
    current_turn_index = session.current_turn_index

    participants
    |> Enum.with_index()
    |> Enum.map(fn {participant, idx} ->
      score = Map.get(score_map, participant.id)

      {value, state, color} =
        determine_score_state(score, idx, current_turn_index, current_question)

      %{
        value: value,
        state: state,
        participant_name: participant.name,
        participant_id: participant.id,
        color: color,
        is_current_turn: idx == current_turn_index
      }
    end)
  end

  defp determine_score_state(score, idx, current_turn_index, current_question) do
    cond do
      score != nil ->
        {score.value, :scored, get_score_color(current_question, score.value)}

      idx > current_turn_index ->
        {nil, :pending, nil}

      idx < current_turn_index ->
        {nil, :skipped, nil}

      true ->
        {nil, :current, nil}
    end
  end

  defp calculate_readiness(all_participants, score_map, all_turns_done) do
    eligible_participants =
      Enum.filter(all_participants, fn p ->
        p.status == "active" and not p.is_facilitator and not p.is_observer
      end)

    # Count participants who are ready:
    # - Clicked "I'm Ready to Continue" (is_ready = true), OR
    # - Were skipped (no score when all turns done)
    # Note: Having a score (clicking Done) does NOT count as ready
    ready_count =
      Enum.count(eligible_participants, fn p ->
        was_skipped = all_turns_done and not Map.has_key?(score_map, p.id)
        p.is_ready or was_skipped
      end)

    eligible_count = length(eligible_participants)
    all_ready = eligible_count > 0 and ready_count == eligible_count

    {ready_count, eligible_count, all_ready}
  end

  @doc """
  Loads notes for a specific question.
  """
  def load_notes(socket, session, question_index) do
    notes = Notes.list_notes_for_question(session, question_index)
    assign(socket, question_notes: notes)
  end

  @doc """
  Loads summary data for summary, actions, and completed states.
  """
  def load_summary_data(socket, session) do
    if session.state in ["summary", "actions", "completed"] do
      # Reuse cached template if available, otherwise load it
      template = get_or_load_template(socket, session.template_id)
      scores_summary = Scoring.get_all_scores_summary(session, template)
      all_notes = Notes.list_all_notes(session)

      # Get individual scores grouped by question (ordered by participant joined_at)
      participants = socket.assigns.participants
      individual_scores = Scoring.get_all_individual_scores(session, participants, template)

      # Group notes by question_index
      notes_by_question = Enum.group_by(all_notes, & &1.question_index)

      # Single pass grouping instead of triple filtering
      grouped = Enum.group_by(scores_summary, & &1.color)

      socket
      |> assign(summary_template: template)
      |> assign(scores_summary: scores_summary)
      |> assign(all_notes: all_notes)
      |> assign(individual_scores: individual_scores)
      |> assign(notes_by_question: notes_by_question)
      |> assign(strengths: Map.get(grouped, :green, []))
      |> assign(concerns: Map.get(grouped, :red, []))
      |> assign(neutral: Map.get(grouped, :amber, []))
    else
      socket
      |> assign(summary_template: nil)
      |> assign(scores_summary: [])
      |> assign(all_notes: [])
      |> assign(individual_scores: %{})
      |> assign(notes_by_question: %{})
      |> assign(strengths: [])
      |> assign(concerns: [])
      |> assign(neutral: [])
    end
  end

  @doc """
  Loads or returns cached template.
  """
  def get_or_load_template(socket, template_id) do
    cached = socket.assigns[:template] || socket.assigns[:summary_template]

    if cached && cached.id == template_id do
      cached
    else
      Workshops.get_template_with_questions(template_id)
    end
  end

  @doc """
  Loads actions data for summary, actions, and completed states.
  """
  def load_actions_data(socket, session) do
    if session.state in ["summary", "actions", "completed"] do
      actions = Notes.list_all_actions(session)

      socket
      |> assign(all_actions: actions)
      |> assign(action_count: length(actions))
    else
      socket
      |> assign(all_actions: [])
      |> assign(action_count: 0)
    end
  end
end
