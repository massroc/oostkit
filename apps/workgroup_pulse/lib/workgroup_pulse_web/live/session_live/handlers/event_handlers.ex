defmodule WorkgroupPulseWeb.SessionLive.Handlers.EventHandlers do
  @moduledoc """
  Handlers for user events (handle_event callbacks) in the session LiveView.
  """

  import Phoenix.Component, only: [assign: 2]
  import Phoenix.LiveView, only: [push_event: 3, push_navigate: 2, put_flash: 3]

  alias WorkgroupPulse.Export
  alias WorkgroupPulse.Notes
  alias WorkgroupPulse.Scoring
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulseWeb.SessionLive.Helpers.DataLoaders
  alias WorkgroupPulseWeb.SessionLive.Helpers.StateHelpers
  alias WorkgroupPulseWeb.SessionLive.TimerHandler

  import WorkgroupPulseWeb.SessionLive.OperationHelpers

  require Logger

  # Workshop flow events

  @doc """
  Handles start_workshop event.
  Only facilitator can start the workshop.
  """
  def handle_start_workshop(socket) do
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

  # Intro events

  @doc """
  Handles intro_next event.
  Advances to the next intro step.
  """
  def handle_intro_next(socket) do
    current_step = socket.assigns.intro_step
    {:noreply, assign(socket, intro_step: min(current_step + 1, 4))}
  end

  @doc """
  Handles intro_prev event.
  Goes back to the previous intro step.
  """
  def handle_intro_prev(socket) do
    current_step = socket.assigns.intro_step
    {:noreply, assign(socket, intro_step: max(current_step - 1, 1))}
  end

  @doc """
  Handles skip_intro event.
  Advances directly to scoring phase.
  """
  def handle_skip_intro(socket) do
    handle_continue_to_scoring(socket)
  end

  @doc """
  Handles carousel_navigate event.
  Dispatches based on which carousel sent the event.
  """
  def handle_carousel_navigate(socket, "intro-carousel", index) do
    step = max(1, min(index + 1, 4))
    {:noreply, assign(socket, intro_step: step)}
  end

  def handle_carousel_navigate(socket, "scoring-carousel", index) do
    sheet = if index == 1, do: :notes, else: :main
    {:noreply, assign(socket, active_sheet: sheet)}
  end

  def handle_carousel_navigate(socket, _carousel, _index) do
    {:noreply, socket}
  end

  @doc """
  Handles continue_to_scoring event.
  Advances from intro to scoring phase.
  """
  def handle_continue_to_scoring(socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    handle_operation(
      socket,
      Sessions.advance_to_scoring(session),
      "Failed to advance to scoring",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> DataLoaders.load_scoring_data(updated_session, participant)
        |> TimerHandler.start_phase_timer(updated_session)
      end
    )
  end

  # Scoring events

  @doc """
  Handles select_score event.
  Parses the score value and immediately submits it.
  """
  def handle_select_score(socket, params) do
    score = params["score"] || params["value"]

    int_value =
      cond do
        is_integer(score) -> score
        is_binary(score) and score != "" -> String.to_integer(score)
        true -> nil
      end

    if int_value do
      socket = assign(socket, selected_value: int_value)
      do_submit_score(socket, int_value)
    else
      {:noreply, socket}
    end
  end

  @doc """
  Handles submit_score event.
  Submits the selected score for the current question.
  """
  def handle_submit_score(socket) do
    do_submit_score(socket, socket.assigns.selected_value)
  end

  @doc """
  Handles edit_my_score event.
  Reopens the score overlay so the participant can change their score.
  Only works during their turn before it's locked.
  """
  def handle_edit_my_score(socket) do
    if socket.assigns.is_my_turn and not socket.assigns.my_turn_locked do
      {:noreply, assign(socket, show_score_overlay: true)}
    else
      {:noreply, socket}
    end
  end

  @doc """
  Handles close_score_overlay event.
  Closes the score overlay when clicking outside it.
  """
  def handle_close_score_overlay(socket) do
    {:noreply, assign(socket, show_score_overlay: false)}
  end

  @doc """
  Handles complete_turn event.
  Locks the current participant's turn and advances to the next.
  """
  def handle_complete_turn(socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant
    question_index = session.current_question_index

    case Scoring.lock_participant_turn(session, participant, question_index) do
      {:ok, _score} ->
        case Sessions.advance_turn(session) do
          {:ok, updated_session} ->
            {:noreply,
             socket
             |> assign(session: updated_session)
             |> assign(my_turn_locked: true)
             |> DataLoaders.load_scoring_data(updated_session, participant)}

          {:error, reason} ->
            Logger.error("Failed to advance turn: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Failed to advance turn")}
        end

      {:error, :no_score} ->
        {:noreply, put_flash(socket, :error, "Please place a score first")}
    end
  end

  @doc """
  Handles skip_turn event.
  Skips the current participant's turn.
  """
  def handle_skip_turn(socket) do
    participant = socket.assigns.participant

    handle_operation(
      socket,
      Sessions.skip_turn(socket.assigns.session),
      "Failed to skip turn",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> DataLoaders.load_scoring_data(updated_session, participant)
      end
    )
  end

  @doc """
  Handles mark_ready event.
  Marks the participant as ready.
  """
  def handle_mark_ready(socket) do
    participant = socket.assigns.participant

    handle_operation(
      socket,
      Sessions.set_participant_ready(participant, true),
      "Failed to mark as ready",
      &assign(&1, participant: &2)
    )
  end

  # UI toggle events

  @doc """
  Handles show_criterion_info event - opens the criterion info popup for a question.
  """
  def handle_show_criterion_info(socket, question_index) do
    {:noreply, assign(socket, show_criterion_popup: question_index)}
  end

  @doc """
  Handles close_criterion_info event - closes the criterion info popup.
  """
  def handle_close_criterion_info(socket) do
    {:noreply, assign(socket, show_criterion_popup: nil)}
  end

  @doc """
  Handles focus_sheet event - brings specified sheet to front.
  Valid sheets: :main, :notes
  """
  def handle_focus_sheet(socket, sheet) when sheet in [:main, :notes] do
    {:noreply, assign(socket, active_sheet: sheet)}
  end

  # Note events

  @doc """
  Handles update_note_input event.
  """
  def handle_update_note_input(socket, value) do
    {:noreply, assign(socket, note_input: value)}
  end

  @doc """
  Handles add_note event.
  Creates a new note for the current question.
  """
  def handle_add_note(socket) do
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
           |> DataLoaders.load_notes(session, question_index)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add note")}
      end
    end
  end

  @doc """
  Handles delete_note event.
  Deletes a note by ID.
  """
  def handle_delete_note(socket, note_id) do
    session = socket.assigns.session
    question_index = session.current_question_index

    note = Enum.find(socket.assigns.question_notes, &(&1.id == note_id))

    if note do
      case Notes.delete_note(note) do
        {:ok, _} ->
          broadcast(session, {:note_updated, question_index})
          {:noreply, DataLoaders.load_notes(socket, session, question_index)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete note")}
      end
    else
      {:noreply, socket}
    end
  end

  # Transition events

  @doc """
  Handles continue_past_transition event.
  Dismisses the mid-workshop transition screen.
  """
  def handle_continue_past_transition(socket) do
    {:noreply, assign(socket, show_mid_transition: false)}
  end

  @doc """
  Handles next_question event.
  Advances to the next question (facilitator only).
  """
  def handle_next_question(socket) do
    do_advance_to_next_question(socket, socket.assigns.participant.is_facilitator)
  end

  @doc """
  Handles continue_to_wrapup event.
  Only facilitator can advance to wrap-up/completed.
  """
  def handle_continue_to_wrapup(socket) do
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
          |> DataLoaders.load_summary_data(updated_session)
          |> TimerHandler.stop_timer()
        end
      )
    else
      {:noreply, socket}
    end
  end

  # Action events

  @doc """
  Handles update_action_input event.
  """
  def handle_update_action_input(socket, value) do
    {:noreply, assign(socket, action_input: value)}
  end

  @doc """
  Handles add_action event.
  Creates a new action for the session.
  """
  def handle_add_action(socket) do
    description = String.trim(socket.assigns.action_input)

    if description == "" do
      {:noreply, socket}
    else
      session = socket.assigns.session

      attrs = %{description: description, owner_name: ""}

      case Notes.create_action(session, attrs) do
        {:ok, action} ->
          broadcast(session, {:action_updated, action.id})

          {:noreply,
           socket
           |> assign(action_input: "")
           |> DataLoaders.load_actions_data(session)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add action")}
      end
    end
  end

  @doc """
  Handles delete_action event.
  Deletes an action by ID.
  """
  def handle_delete_action(socket, action_id) do
    session = socket.assigns.session
    action = Enum.find(socket.assigns.all_actions, &(&1.id == action_id))

    if action do
      case Notes.delete_action(action) do
        {:ok, _} ->
          broadcast(session, {:action_updated, action_id})
          {:noreply, DataLoaders.load_actions_data(socket, session)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete action")}
      end
    else
      {:noreply, socket}
    end
  end

  @doc """
  Handles finish_workshop event.
  Only facilitator can finish the workshop.
  """
  def handle_finish_workshop(socket) do
    participant = socket.assigns.participant

    if participant.is_facilitator do
      do_finish_workshop(socket)
    else
      {:noreply, socket}
    end
  end

  @doc """
  Handles go_back event.
  Only facilitator can navigate back to keep all participants in sync.

  Navigation phases:
  - Question phase ("scoring") - back to previous question (not past Q1)
  - Summary screen ("summary") - back to last question
  - Wrap-up screen ("completed") - back to summary
  """
  def handle_go_back(socket) do
    participant = socket.assigns.participant

    if participant.is_facilitator do
      do_go_back(socket)
    else
      {:noreply, socket}
    end
  end

  # Export events

  @doc """
  Handles toggle_export_modal event.
  """
  def handle_toggle_export_modal(socket) do
    {:noreply, assign(socket, show_export_modal: !socket.assigns.show_export_modal)}
  end

  @doc """
  Handles close_export_modal event.
  """
  def handle_close_export_modal(socket) do
    {:noreply, assign(socket, show_export_modal: false)}
  end

  @doc """
  Handles select_export_content event.
  """
  def handle_select_export_content(socket, content) do
    {:noreply, assign(socket, export_content: content)}
  end

  @doc """
  Handles export event.
  Exports workshop data in the specified format.
  """
  def handle_export(socket, format) do
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
    {:noreply, push_navigate(socket, to: "/")}
  end

  defp do_go_back(socket) do
    session = socket.assigns.session
    do_go_back_from_state(socket, session, session.state)
  end

  # Back from scoring (first question) - can't go back any further
  defp do_go_back_from_state(socket, %{current_question_index: 0}, "scoring") do
    {:noreply, socket}
  end

  # Back from scoring (any other question) goes to previous question
  defp do_go_back_from_state(socket, session, "scoring") do
    go_back_to_previous_question(socket, session)
  end

  defp do_go_back_from_state(socket, session, "summary") do
    Sessions.reset_all_ready(session)
    template = DataLoaders.get_or_load_template(socket, session.template_id)
    last_index = length(template.questions) - 1

    handle_operation(
      socket,
      Sessions.go_back_to_scoring(session, last_index),
      "Failed to go back",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> DataLoaders.load_scoring_data(updated_session, socket.assigns.participant)
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
        |> DataLoaders.load_summary_data(updated_session)
      end
    )
  end

  defp do_go_back_from_state(socket, _session, _state) do
    {:noreply, socket}
  end

  defp go_back_to_previous_question(socket, session) do
    Sessions.reset_all_ready(session)

    handle_operation(
      socket,
      Sessions.go_back_question(session),
      "Failed to go back",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> assign(show_mid_transition: false)
        |> DataLoaders.load_scoring_data(updated_session, socket.assigns.participant)
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
    template = socket.assigns[:template]

    case Scoring.submit_score(session, participant, question_index, selected_value) do
      {:ok, _score} ->
        broadcast(session, {:score_submitted, participant.id, question_index})

        {:noreply,
         socket
         |> assign(my_score: selected_value)
         |> assign(has_submitted: true)
         |> assign(show_score_overlay: false)
         |> DataLoaders.load_scores(session, question_index)
         |> DataLoaders.load_all_questions_scores(session, template)}

      {:error, reason} ->
        Logger.error("Failed to submit score: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Failed to submit score")}
    end
  end

  defp broadcast(session, event) do
    Phoenix.PubSub.broadcast(
      WorkgroupPulse.PubSub,
      Sessions.session_topic(session),
      event
    )
  end

  defp do_advance_to_next_question(socket, false), do: {:noreply, socket}

  defp do_advance_to_next_question(socket, true) do
    session = socket.assigns.session
    Sessions.reset_all_ready(session)

    template = DataLoaders.get_or_load_template(socket, session.template_id)
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
        |> DataLoaders.load_summary_data(updated_session)
        |> TimerHandler.start_phase_timer(updated_session)
      end
    )
  end

  defp do_advance(socket, session, false) do
    participant = socket.assigns.participant
    current_index = session.current_question_index
    template = DataLoaders.get_or_load_template(socket, session.template_id)

    show_transition = StateHelpers.scale_type_changes_at?(template, current_index)

    handle_operation(
      socket,
      Sessions.advance_question(session),
      "Failed to advance to next question",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> assign(show_mid_transition: show_transition)
        |> DataLoaders.load_scoring_data(updated_session, participant)
        |> TimerHandler.start_phase_timer(updated_session)
      end
    )
  end
end
