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
    my_turn_locked = my_score != nil and my_score.turn_locked

    # Turn-based scoring state
    current_turn_participant = Sessions.get_current_turn_participant(session)

    is_my_turn =
      current_turn_participant != nil and current_turn_participant.id == participant.id

    # Check if current turn participant has already submitted (for skip button visibility)
    current_turn_has_score =
      if current_turn_participant do
        Scoring.get_score(session, current_turn_participant, question_index) != nil
      else
        false
      end

    socket
    |> assign(template: template)
    |> assign(total_questions: length(template.questions))
    |> assign(current_question: question)
    |> assign(selected_value: if(my_score, do: my_score.value, else: nil))
    |> assign(my_score: if(my_score, do: my_score.value, else: nil))
    |> assign(has_submitted: my_score != nil)
    |> assign(my_turn_locked: my_turn_locked)
    |> assign(is_my_turn: is_my_turn and not participant.is_observer)
    |> assign(
      current_turn_participant_id: current_turn_participant && current_turn_participant.id
    )
    |> assign(current_turn_has_score: current_turn_has_score)
    |> assign(in_catch_up_phase: session.in_catch_up_phase)
    |> assign(show_facilitator_tips: false)
    |> assign(show_notes: false)
    |> load_scores(session, question_index)
    |> load_notes(session, question_index)
  end

  def load_scoring_data(socket, _session, _participant) do
    reset_scoring_assigns(socket)
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
    |> assign(in_catch_up_phase: false)
    |> assign(all_scores: [])
    |> assign(scores_revealed: false)
    |> assign(score_count: 0)
    |> assign(active_participant_count: 0)
    |> assign(question_notes: [])
    |> assign(show_facilitator_tips: false)
    |> assign(show_notes: false)
  end

  @doc """
  Loads scores for a specific question and builds participant score grid.
  """
  def load_scores(socket, session, question_index) do
    scores = Scoring.list_scores_for_question(session, question_index)
    all_scored = Scoring.all_scored?(session, question_index)

    # Get participants in turn order (active, non-observers)
    participants_in_turn_order = Sessions.get_participants_in_turn_order(session)
    active_count = length(participants_in_turn_order)

    # Build score map for O(1) lookups: participant_id => score
    score_map = Map.new(scores, &{&1.participant_id, &1})

    # Current turn index for determining pending vs skipped
    current_turn_index = session.current_turn_index
    in_catch_up = session.in_catch_up_phase

    # Build full participant grid showing all participants with their states
    participant_scores =
      participants_in_turn_order
      |> Enum.with_index()
      |> Enum.map(fn {participant, idx} ->
        score = Map.get(score_map, participant.id)

        # Determine the state of this participant's score box
        {value, state, color} =
          cond do
            # Has a score
            score != nil ->
              {score.value, :scored,
               get_score_color(socket.assigns[:current_question], score.value)}

            # In catch-up phase - anyone without a score was skipped
            in_catch_up ->
              {nil, :skipped, nil}

            # Turn hasn't reached them yet
            idx > current_turn_index ->
              {nil, :pending, nil}

            # Turn has passed them (they were skipped)
            idx < current_turn_index ->
              {nil, :skipped, nil}

            # It's their turn right now
            true ->
              {nil, :current, nil}
          end

        %{
          value: value,
          state: state,
          participant_name: participant.name,
          participant_id: participant.id,
          color: color,
          is_current_turn: idx == current_turn_index and not in_catch_up
        }
      end)

    # Check if current turn participant has submitted a score (for messaging)
    current_turn_participant = Enum.at(participants_in_turn_order, current_turn_index)

    current_turn_has_score =
      current_turn_participant != nil and Map.has_key?(score_map, current_turn_participant.id)

    socket
    |> assign(all_scores: participant_scores)
    |> assign(scores_revealed: all_scored)
    |> assign(score_count: length(scores))
    |> assign(active_participant_count: active_count)
    |> assign(current_turn_has_score: current_turn_has_score)
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
