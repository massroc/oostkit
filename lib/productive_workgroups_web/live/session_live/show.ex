defmodule ProductiveWorkgroupsWeb.SessionLive.Show do
  @moduledoc """
  Main workshop LiveView - handles the full workshop flow.
  """
  use ProductiveWorkgroupsWeb, :live_view

  alias ProductiveWorkgroups.Export
  alias ProductiveWorkgroups.Notes
  alias ProductiveWorkgroups.Scoring
  alias ProductiveWorkgroups.Sessions
  alias ProductiveWorkgroups.Workshops
  alias ProductiveWorkgroupsWeb.SessionLive.Components.ActionsComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Components.CompletedComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Components.IntroComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Components.LobbyComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Components.ScoringComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Components.SummaryComponent
  alias ProductiveWorkgroupsWeb.SessionLive.TimerHandler
  alias ProductiveWorkgroupsWeb.SessionLive.TurnTimeoutHandler

  import ProductiveWorkgroupsWeb.SessionLive.OperationHelpers
  import ProductiveWorkgroupsWeb.SessionLive.ScoreHelpers

  require Logger

  @impl true
  def mount(%{"code" => code}, session, socket) do
    browser_token = session["browser_token"]

    case Sessions.get_session_by_code(code) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Session not found. Please check the code and try again.")
         |> redirect(to: ~p"/")}

      workshop_session ->
        mount_with_session(socket, workshop_session, browser_token, code)
    end
  end

  defp mount_with_session(socket, _workshop_session, nil, code) do
    {:ok, redirect(socket, to: ~p"/session/#{code}/join")}
  end

  defp mount_with_session(socket, workshop_session, browser_token, code) do
    participant = Sessions.get_participant_by_token(workshop_session, browser_token)
    mount_with_participant(socket, workshop_session, participant, code)
  end

  defp mount_with_participant(socket, _workshop_session, nil, code) do
    {:ok, redirect(socket, to: ~p"/session/#{code}/join")}
  end

  defp mount_with_participant(socket, workshop_session, participant, _code) do
    if connected?(socket), do: Sessions.subscribe(workshop_session)

    participants = Sessions.list_participants(workshop_session)

    {:ok,
     socket
     |> assign(page_title: "Workshop Session")
     |> assign(session: workshop_session)
     |> assign(participant: participant)
     |> assign(participants: participants)
     |> assign(intro_step: 1)
     |> assign(show_mid_transition: false)
     |> assign(show_facilitator_tips: false)
     |> assign(show_notes: false)
     |> assign(note_input: "")
     |> assign(show_export_modal: false)
     |> assign(export_content: "all")
     |> TimerHandler.init_timer_assigns()
     |> TurnTimeoutHandler.init_timeout_assigns()
     |> load_scoring_data(workshop_session, participant)
     |> load_summary_data(workshop_session)
     |> load_actions_data(workshop_session)
     |> TimerHandler.maybe_start_timer()
     |> TurnTimeoutHandler.start_turn_timeout()}
  end

  @impl true
  def handle_info({:participant_joined, participant}, socket) do
    # Avoid duplicates by checking if participant already exists
    participants = socket.assigns.participants

    if Enum.any?(participants, &(&1.id == participant.id)) do
      {:noreply, socket}
    else
      {:noreply, assign(socket, participants: participants ++ [participant])}
    end
  end

  @impl true
  def handle_info({:participant_left, participant_id}, socket) do
    participants =
      Enum.reject(socket.assigns.participants, fn p -> p.id == participant_id end)

    {:noreply, assign(socket, participants: participants)}
  end

  @impl true
  def handle_info({:participant_updated, participant}, socket) do
    participants =
      Enum.map(socket.assigns.participants, fn p ->
        if p.id == participant.id, do: participant, else: p
      end)

    {:noreply, assign(socket, participants: participants)}
  end

  @impl true
  def handle_info({:participant_ready, participant}, socket) do
    participants =
      Enum.map(socket.assigns.participants, fn p ->
        if p.id == participant.id, do: participant, else: p
      end)

    {:noreply, assign(socket, participants: participants)}
  end

  @impl true
  def handle_info({:session_started, session}, socket) do
    old_session = socket.assigns.session

    socket =
      socket
      |> assign(session: session)
      |> handle_state_transition(old_session, session)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:session_updated, session}, socket) do
    old_session = socket.assigns.session

    socket =
      socket
      |> assign(session: session)
      |> handle_state_transition(old_session, session)

    {:noreply, socket}
  end

  # Handle score submission broadcast from other participants
  @impl true
  def handle_info({:score_submitted, _participant_id, question_index}, socket) do
    session = socket.assigns.session

    if session.state == "scoring" and session.current_question_index == question_index do
      {:noreply, load_scores(socket, session, question_index)}
    else
      {:noreply, socket}
    end
  end

  # Handle note updates from other participants
  @impl true
  def handle_info({:note_updated, question_index}, socket) do
    session = socket.assigns.session

    if session.state == "scoring" and session.current_question_index == question_index do
      {:noreply, load_notes(socket, session, question_index)}
    else
      {:noreply, socket}
    end
  end

  # Handle action updates from other participants
  @impl true
  def handle_info({:action_updated, _action_id}, socket) do
    session = socket.assigns.session

    if session.state in ["summary", "actions", "completed"] do
      {:noreply, load_actions_data(socket, session)}
    else
      {:noreply, socket}
    end
  end

  # Handle flash messages from child components
  @impl true
  def handle_info({:flash, kind, message}, socket) do
    {:noreply, put_flash(socket, kind, message)}
  end

  # Handle reload request from ActionFormComponent
  @impl true
  def handle_info(:reload_actions, socket) do
    {:noreply, load_actions_data(socket, socket.assigns.session)}
  end

  # Handle turn advancement in turn-based scoring
  @impl true
  def handle_info({:turn_advanced, _payload}, socket) do
    # Always reload the session and full scoring data when turn changes
    updated_session = Sessions.get_session!(socket.assigns.session.id)
    participant = socket.assigns.participant

    # Reload full scoring data to ensure all assigns are correct
    {:noreply,
     socket
     |> assign(session: updated_session)
     |> load_scoring_data(updated_session, participant)}
  end

  # Handle catch-up phase start
  @impl true
  def handle_info({:catch_up_started, payload}, socket) do
    participant = socket.assigns.participant
    is_my_turn = participant.id in payload.skipped_participant_ids and not participant.is_observer

    {:noreply,
     socket
     |> assign(in_catch_up_phase: true)
     |> assign(is_my_turn: is_my_turn)}
  end

  # Handle catch-up phase end
  @impl true
  def handle_info({:catch_up_ended, _payload}, socket) do
    {:noreply,
     socket
     |> assign(in_catch_up_phase: false)
     |> assign(is_my_turn: false)}
  end

  # Handle row lock (when group advances to next question)
  @impl true
  def handle_info({:row_locked, _payload}, socket) do
    session = socket.assigns.session
    {:noreply, load_scores(socket, session, session.current_question_index)}
  end

  # Handle timer tick for facilitator timer countdown
  @impl true
  def handle_info(:timer_tick, socket) do
    TimerHandler.handle_timer_tick(socket)
  end

  # Handle turn timeout tick for auto-skipping inactive participants
  @impl true
  def handle_info(:turn_timeout_tick, socket) do
    case TurnTimeoutHandler.handle_timeout_tick(socket) do
      {:continue, socket} ->
        {:noreply, socket}

      {:auto_skipped, updated_session, socket} ->
        participant = socket.assigns.participant

        socket =
          socket
          |> assign(session: updated_session)
          |> load_scoring_data(updated_session, participant)
          |> TurnTimeoutHandler.start_turn_timeout()

        {:noreply, socket}

      {:noreply, socket} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # Helper for handling state transitions in session_updated broadcasts
  defp handle_state_transition(socket, old_session, session) do
    state_changed = old_session.state != session.state
    question_changed = old_session.current_question_index != session.current_question_index
    turn_changed = old_session.current_turn_index != session.current_turn_index
    catch_up_changed = old_session.in_catch_up_phase != session.in_catch_up_phase

    case {state_changed, question_changed, session.state} do
      {true, _, "scoring"} ->
        socket
        |> load_scoring_data(session, socket.assigns.participant)
        |> TimerHandler.maybe_restart_timer_on_transition(old_session, session)
        |> TurnTimeoutHandler.maybe_restart_on_turn_change(old_session, session)

      {_, true, "scoring"} ->
        # Load scoring data first to ensure template is available
        socket = load_scoring_data(socket, session, socket.assigns.participant)
        template = socket.assigns.template

        # Show mid-workshop transition when scale type changes (e.g., balance -> maximal)
        show_transition = scale_type_changes_at?(template, old_session.current_question_index)

        socket
        |> assign(show_mid_transition: show_transition)
        |> TimerHandler.maybe_restart_timer_on_transition(old_session, session)
        |> TurnTimeoutHandler.maybe_restart_on_turn_change(old_session, session)

      {false, false, "scoring"} when turn_changed or catch_up_changed ->
        # Turn changed within the same question - reload scoring data
        socket
        |> load_scoring_data(session, socket.assigns.participant)
        |> TurnTimeoutHandler.maybe_restart_on_turn_change(old_session, session)

      {true, _, "summary"} ->
        socket
        |> load_summary_data(session)
        |> load_actions_data(session)
        |> TimerHandler.maybe_restart_timer_on_transition(old_session, session)
        |> TurnTimeoutHandler.cancel_turn_timeout()

      {true, _, "actions"} ->
        # Don't restart timer when transitioning from summary to actions - shared timer
        socket
        |> load_summary_data(session)
        |> load_actions_data(session)
        |> TurnTimeoutHandler.cancel_turn_timeout()

      {true, _, "completed"} ->
        socket
        |> load_summary_data(session)
        |> load_actions_data(session)
        |> TimerHandler.stop_timer()
        |> TurnTimeoutHandler.cancel_turn_timeout()

      _ ->
        socket
    end
  end

  @impl true
  def handle_event("start_workshop", _params, socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    if participant.is_facilitator do
      handle_operation(
        socket,
        Sessions.start_session(session),
        "Failed to start workshop",
        &assign(&1, session: &2)
      )
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("intro_next", _params, socket) do
    current_step = socket.assigns.intro_step
    {:noreply, assign(socket, intro_step: min(current_step + 1, 4))}
  end

  @impl true
  def handle_event("intro_prev", _params, socket) do
    current_step = socket.assigns.intro_step
    {:noreply, assign(socket, intro_step: max(current_step - 1, 1))}
  end

  @impl true
  def handle_event("skip_intro", _params, socket) do
    {:noreply, assign(socket, intro_step: 4)}
  end

  @impl true
  def handle_event("continue_to_scoring", _params, socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    if participant.is_facilitator do
      handle_operation(
        socket,
        Sessions.advance_to_scoring(session),
        "Failed to advance to scoring",
        fn socket, updated_session ->
          socket
          |> assign(session: updated_session)
          |> load_scoring_data(updated_session, participant)
          |> TimerHandler.start_phase_timer(updated_session)
        end
      )
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("select_score", params, socket) do
    score = params["score"] || params["value"]

    int_value =
      cond do
        is_integer(score) -> score
        is_binary(score) and score != "" -> String.to_integer(score)
        true -> nil
      end

    if int_value do
      {:noreply, assign(socket, selected_value: int_value)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("submit_score", _params, socket) do
    do_submit_score(socket, socket.assigns.selected_value)
  end

  # Turn-based scoring: complete the current participant's turn
  @impl true
  def handle_event("complete_turn", _params, socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant
    question_index = session.current_question_index

    # Lock the participant's turn
    case Scoring.lock_participant_turn(session, participant, question_index) do
      {:ok, _score} ->
        # Advance to the next participant's turn
        case Sessions.advance_turn(session) do
          {:ok, updated_session} ->
            {:noreply,
             socket
             |> assign(session: updated_session)
             |> assign(my_turn_locked: true)
             |> load_scoring_data(updated_session, participant)
             |> TurnTimeoutHandler.maybe_restart_on_turn_change(session, updated_session)}

          {:error, reason} ->
            Logger.error("Failed to advance turn: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Failed to advance turn")}
        end

      {:error, :no_score} ->
        {:noreply, put_flash(socket, :error, "Please place a score first")}
    end
  end

  # Turn-based scoring: skip the current participant
  @impl true
  def handle_event("skip_turn", _params, socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    handle_operation(
      socket,
      Sessions.skip_turn(session),
      "Failed to skip turn",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> load_scoring_data(updated_session, participant)
        |> TurnTimeoutHandler.maybe_restart_on_turn_change(session, updated_session)
      end
    )
  end

  @impl true
  def handle_event("mark_ready", _params, socket) do
    participant = socket.assigns.participant

    handle_operation(
      socket,
      Sessions.set_participant_ready(participant, true),
      "Failed to mark as ready",
      &assign(&1, participant: &2)
    )
  end

  # Note handlers - kept for backward compatibility with tests
  @impl true
  def handle_event("toggle_facilitator_tips", _params, socket) do
    {:noreply, assign(socket, show_facilitator_tips: !socket.assigns.show_facilitator_tips)}
  end

  @impl true
  def handle_event("toggle_notes", _params, socket) do
    {:noreply, assign(socket, show_notes: !socket.assigns.show_notes)}
  end

  @impl true
  def handle_event("update_note_input", %{"note" => value}, socket) do
    {:noreply, assign(socket, note_input: value)}
  end

  @impl true
  def handle_event("add_note", _params, socket) do
    content = String.trim(socket.assigns.note_input)

    if content == "" do
      {:noreply, socket}
    else
      session = socket.assigns.session
      participant = socket.assigns.participant
      question_index = session.current_question_index

      attrs = %{content: content, author_name: participant.name}

      case Notes.create_note(session, question_index, attrs) do
        {:ok, _note} ->
          broadcast(session, {:note_updated, question_index})

          {:noreply,
           socket
           |> assign(note_input: "")
           |> load_notes(session, question_index)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add note")}
      end
    end
  end

  @impl true
  def handle_event("delete_note", %{"id" => note_id}, socket) do
    session = socket.assigns.session
    question_index = session.current_question_index

    note = Enum.find(socket.assigns.question_notes, &(&1.id == note_id))

    if note do
      case Notes.delete_note(note) do
        {:ok, _} ->
          broadcast(session, {:note_updated, question_index})
          {:noreply, load_notes(socket, session, question_index)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete note")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("continue_past_transition", _params, socket) do
    {:noreply, assign(socket, show_mid_transition: false)}
  end

  @impl true
  def handle_event("next_question", _params, socket) do
    do_advance_to_next_question(socket, socket.assigns.participant.is_facilitator)
  end

  @impl true
  def handle_event("continue_to_actions", _params, socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    if participant.is_facilitator do
      handle_operation(
        socket,
        Sessions.advance_to_actions(session),
        "Failed to advance to actions",
        fn socket, updated_session ->
          socket
          |> assign(session: updated_session)
          |> load_actions_data(updated_session)
        end
      )
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("continue_to_wrapup", _params, socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    if participant.is_facilitator do
      handle_operation(
        socket,
        Sessions.advance_to_completed(session),
        "Failed to advance to wrap-up",
        fn socket, updated_session ->
          socket
          |> assign(session: updated_session)
          |> load_summary_data(updated_session)
          |> load_actions_data(updated_session)
          |> TimerHandler.stop_timer()
        end
      )
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_action", %{"id" => action_id}, socket) do
    session = socket.assigns.session
    action = Enum.find(socket.assigns.all_actions, &(&1.id == action_id))

    if action do
      case Notes.delete_action(action) do
        {:ok, _} ->
          broadcast(session, {:action_updated, action_id})
          {:noreply, load_actions_data(socket, session)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete action")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("finish_workshop", _params, socket) do
    participant = socket.assigns.participant

    if participant.is_facilitator do
      do_finish_workshop(socket)
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("go_back", _params, socket) do
    participant = socket.assigns.participant

    if participant.is_facilitator do
      do_go_back(socket)
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_export_modal", _params, socket) do
    {:noreply, assign(socket, show_export_modal: !socket.assigns.show_export_modal)}
  end

  @impl true
  def handle_event("close_export_modal", _params, socket) do
    {:noreply, assign(socket, show_export_modal: false)}
  end

  @impl true
  def handle_event("select_export_content", %{"content" => content}, socket) do
    {:noreply, assign(socket, export_content: content)}
  end

  @impl true
  def handle_event("export", %{"format" => format}, socket) do
    session = socket.assigns.session
    content = socket.assigns.export_content

    format_atom = String.to_existing_atom(format)
    content_atom = String.to_existing_atom(content)

    case Export.export(session, format: format_atom, content: content_atom) do
      {:ok, {filename, content_type, data}} ->
        {:noreply,
         socket
         |> assign(show_export_modal: false)
         |> push_event("download", %{filename: filename, content_type: content_type, data: data})}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to export data")}
    end
  end

  # Private helper functions

  defp do_finish_workshop(socket) do
    session = socket.assigns.session

    # Session is already in "completed" state on the wrap-up page - just navigate home
    if session.state == "completed" do
      {:noreply, push_navigate(socket, to: "/")}
    else
      # Legacy: handle finish from actions state
      case Sessions.complete_session(session) do
        {:ok, _updated_session} ->
          {:noreply, push_navigate(socket, to: "/")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to complete workshop")}
      end
    end
  end

  defp do_go_back(socket) do
    session = socket.assigns.session
    do_go_back_from_state(socket, session, session.state)
  end

  defp do_go_back_from_state(socket, session, "scoring")
       when session.current_question_index == 0 do
    # If on first question scoring entry (not results), go back to intro
    if socket.assigns.scores_revealed do
      # On results page - just unreveal scores for current question
      unreveal_current_question_scores(socket, session)
    else
      # On scoring entry - go back to intro
      go_back_to_intro(socket, session)
    end
  end

  defp do_go_back_from_state(socket, session, "scoring") do
    if socket.assigns.scores_revealed do
      # On results page - unreveal current question's scores to return to scoring entry
      unreveal_current_question_scores(socket, session)
    else
      # On scoring entry - go back to previous question's results
      go_back_to_previous_question_results(socket, session)
    end
  end

  defp do_go_back_from_state(socket, session, "summary") do
    Sessions.reset_all_ready(session)
    template = get_or_load_template(socket, session.template_id)
    last_index = length(template.questions) - 1
    Scoring.unreveal_scores(session, last_index)

    # Don't restart timer - timer only moves forward, keeps current countdown
    handle_operation(
      socket,
      Sessions.go_back_to_scoring(session, last_index),
      "Failed to go back",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> load_scoring_data(updated_session, socket.assigns.participant)
        |> assign(scores_revealed: false)
        |> assign(has_submitted: false)
      end
    )
  end

  defp do_go_back_from_state(socket, session, "actions") do
    Sessions.reset_all_ready(session)

    handle_operation(
      socket,
      Sessions.go_back_to_summary(session),
      "Failed to go back",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> load_summary_data(updated_session)
      end
    )
  end

  defp do_go_back_from_state(socket, session, "completed") do
    Sessions.reset_all_ready(session)

    handle_operation(
      socket,
      Sessions.go_back_to_summary(session),
      "Failed to go back",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> load_summary_data(updated_session)
      end
    )
  end

  defp do_go_back_from_state(socket, _session, _state) do
    # Cannot go back from lobby or intro
    {:noreply, socket}
  end

  defp unreveal_current_question_scores(socket, session) do
    Sessions.reset_all_ready(session)
    current_index = session.current_question_index
    Scoring.unreveal_scores(session, current_index)

    {:noreply,
     socket
     |> load_scoring_data(session, socket.assigns.participant)
     |> assign(scores_revealed: false)
     |> assign(has_submitted: false)}
  end

  defp go_back_to_previous_question_results(socket, session) do
    Sessions.reset_all_ready(session)
    # Don't unreveal - we want to show the previous question's results
    # Don't restart timer - timer only moves forward, keeps current countdown

    handle_operation(
      socket,
      Sessions.go_back_question(session),
      "Failed to go back",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> assign(show_mid_transition: false)
        |> load_scoring_data(updated_session, socket.assigns.participant)
      end
    )
  end

  defp go_back_to_intro(socket, session) do
    Sessions.reset_all_ready(session)

    handle_operation(
      socket,
      Sessions.go_back_to_intro(session),
      "Failed to go back",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> assign(intro_step: 4)
        |> TimerHandler.stop_timer()
      end
    )
  end

  defp do_submit_score(socket, nil) do
    {:noreply, put_flash(socket, :error, "Please select a score first")}
  end

  defp do_submit_score(socket, selected_value) do
    session = socket.assigns.session
    participant = socket.assigns.participant
    question_index = session.current_question_index

    case Scoring.submit_score(session, participant, question_index, selected_value) do
      {:ok, _score} ->
        maybe_reveal_scores(session, question_index)
        broadcast(session, {:score_submitted, participant.id, question_index})

        {:noreply,
         socket
         |> assign(my_score: selected_value)
         |> assign(has_submitted: true)
         |> load_scores(session, question_index)}

      {:error, reason} ->
        Logger.error("Failed to submit score: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Failed to submit score")}
    end
  end

  defp maybe_reveal_scores(session, question_index) do
    if Scoring.all_scored?(session, question_index) do
      Scoring.reveal_scores(session, question_index)
    end
  end

  # Unified broadcast helper - uses Sessions context for topic generation
  defp broadcast(session, event) do
    Phoenix.PubSub.broadcast(
      ProductiveWorkgroups.PubSub,
      Sessions.session_topic(session),
      event
    )
  end

  defp do_advance_to_next_question(socket, false), do: {:noreply, socket}

  defp do_advance_to_next_question(socket, true) do
    session = socket.assigns.session
    Sessions.reset_all_ready(session)

    # Reuse cached template
    template = get_or_load_template(socket, session.template_id)
    is_last_question = session.current_question_index + 1 >= length(template.questions)

    do_advance(socket, session, is_last_question)
  end

  defp do_advance(socket, session, true) do
    handle_operation(
      socket,
      Sessions.advance_to_summary(session),
      "Failed to advance to summary",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> load_summary_data(updated_session)
        |> TimerHandler.start_phase_timer(updated_session)
      end
    )
  end

  defp do_advance(socket, session, false) do
    participant = socket.assigns.participant
    current_index = session.current_question_index
    template = get_or_load_template(socket, session.template_id)

    # Show mid-workshop transition when scale type changes (e.g., balance -> maximal)
    show_transition = scale_type_changes_at?(template, current_index)

    handle_operation(
      socket,
      Sessions.advance_question(session),
      "Failed to advance to next question",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> assign(show_mid_transition: show_transition)
        |> load_scoring_data(updated_session, participant)
        |> TimerHandler.start_phase_timer(updated_session)
      end
    )
  end

  # Scoring data helpers

  defp load_scoring_data(socket, session, participant) do
    if session.state == "scoring" do
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
    else
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
  end

  defp load_scores(socket, session, question_index) do
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

  defp load_notes(socket, session, question_index) do
    notes = Notes.list_notes_for_question(session, question_index)
    assign(socket, question_notes: notes)
  end

  defp load_summary_data(socket, session) do
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

  # Reuse cached template to avoid repeated database queries
  defp get_or_load_template(socket, template_id) do
    cached = socket.assigns[:template] || socket.assigns[:summary_template]

    if cached && cached.id == template_id do
      cached
    else
      Workshops.get_template_with_questions(template_id)
    end
  end

  defp load_actions_data(socket, session) do
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900">
      {render_facilitator_timer(assigns)}
      <%= case @session.state do %>
        <% "lobby" -> %>
          <LobbyComponent.render
            session={@session}
            participant={@participant}
            participants={@participants}
          />
        <% "intro" -> %>
          <IntroComponent.render
            intro_step={@intro_step}
            participant={@participant}
          />
        <% "scoring" -> %>
          <ScoringComponent.render
            session={@session}
            participant={@participant}
            participants={@participants}
            current_question={@current_question}
            total_questions={@total_questions}
            all_scores={@all_scores}
            selected_value={@selected_value}
            my_score={@my_score}
            has_submitted={@has_submitted}
            is_my_turn={@is_my_turn}
            current_turn_participant_id={@current_turn_participant_id}
            current_turn_has_score={@current_turn_has_score}
            in_catch_up_phase={@in_catch_up_phase}
            my_turn_locked={@my_turn_locked}
            scores_revealed={@scores_revealed}
            score_count={@score_count}
            active_participant_count={@active_participant_count}
            show_mid_transition={@show_mid_transition}
            show_facilitator_tips={@show_facilitator_tips}
            question_notes={@question_notes}
            show_notes={@show_notes}
            note_input={@note_input}
          />
        <% "summary" -> %>
          <SummaryComponent.render
            session={@session}
            participant={@participant}
            participants={@participants}
            scores_summary={@scores_summary}
            individual_scores={@individual_scores}
            notes_by_question={@notes_by_question}
          />
        <% "actions" -> %>
          <ActionsComponent.render
            session={@session}
            participant={@participant}
            all_actions={@all_actions}
            action_count={@action_count}
          />
        <% "completed" -> %>
          <CompletedComponent.render
            session={@session}
            participant={@participant}
            scores_summary={@scores_summary}
            strengths={@strengths}
            concerns={@concerns}
            all_actions={@all_actions}
            action_count={@action_count}
            show_export_modal={@show_export_modal}
            export_content={@export_content}
          />
        <% _ -> %>
          <LobbyComponent.render
            session={@session}
            participant={@participant}
            participants={@participants}
          />
      <% end %>
    </div>
    """
  end

  defp render_facilitator_timer(assigns) do
    ~H"""
    <%= if @participant.is_facilitator and @timer_enabled and @timer_remaining do %>
      <.facilitator_timer
        remaining_seconds={@timer_remaining}
        total_seconds={@segment_duration}
        phase_name={@timer_phase_name}
        warning_threshold={@timer_warning_threshold}
      />
    <% end %>
    """
  end

  # Check if advancing from current_index would cross a scale type boundary
  # (e.g., from "balance" to "maximal" questions)
  defp scale_type_changes_at?(template, current_index) do
    current_question = Enum.find(template.questions, &(&1.index == current_index))
    next_question = Enum.find(template.questions, &(&1.index == current_index + 1))

    case {current_question, next_question} do
      {%{scale_type: current_type}, %{scale_type: next_type}} when current_type != next_type ->
        true

      _ ->
        false
    end
  end
end
