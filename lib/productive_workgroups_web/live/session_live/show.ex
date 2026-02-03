defmodule ProductiveWorkgroupsWeb.SessionLive.Show do
  @moduledoc """
  Main workshop LiveView - handles the full workshop flow.
  """
  use ProductiveWorkgroupsWeb, :live_view

  alias ProductiveWorkgroups.Sessions
  alias ProductiveWorkgroupsWeb.SessionLive.Components.ActionsComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Components.CompletedComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Components.IntroComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Components.LobbyComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Components.ScoringComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Components.SummaryComponent
  alias ProductiveWorkgroupsWeb.SessionLive.Handlers.EventHandlers
  alias ProductiveWorkgroupsWeb.SessionLive.Handlers.MessageHandlers
  alias ProductiveWorkgroupsWeb.SessionLive.Helpers.DataLoaders
  alias ProductiveWorkgroupsWeb.SessionLive.TimerHandler
  alias ProductiveWorkgroupsWeb.SessionLive.TurnTimeoutHandler

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
    participant = Sessions.get_participant(workshop_session, browser_token)
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
     |> DataLoaders.load_scoring_data(workshop_session, participant)
     |> DataLoaders.load_summary_data(workshop_session)
     |> DataLoaders.load_actions_data(workshop_session)
     |> TimerHandler.maybe_start_timer()
     |> TurnTimeoutHandler.start_turn_timeout()}
  end

  @impl true
  def handle_info({:participant_joined, participant}, socket) do
    {:noreply, MessageHandlers.handle_participant_joined(socket, participant)}
  end

  @impl true
  def handle_info({:participant_left, participant_id}, socket) do
    {:noreply, MessageHandlers.handle_participant_left(socket, participant_id)}
  end

  @impl true
  def handle_info({:participant_updated, participant}, socket) do
    {:noreply, MessageHandlers.handle_participant_updated(socket, participant)}
  end

  @impl true
  def handle_info({:participant_ready, participant}, socket) do
    {:noreply, MessageHandlers.handle_participant_ready(socket, participant)}
  end

  @impl true
  def handle_info({:session_started, session}, socket) do
    {:noreply, MessageHandlers.handle_session_started(socket, session)}
  end

  @impl true
  def handle_info({:session_updated, session}, socket) do
    {:noreply, MessageHandlers.handle_session_updated(socket, session)}
  end

  @impl true
  def handle_info({:score_submitted, participant_id, question_index}, socket) do
    {:noreply, MessageHandlers.handle_score_submitted(socket, participant_id, question_index)}
  end

  @impl true
  def handle_info({:note_updated, question_index}, socket) do
    {:noreply, MessageHandlers.handle_note_updated(socket, question_index)}
  end

  @impl true
  def handle_info({:action_updated, action_id}, socket) do
    {:noreply, MessageHandlers.handle_action_updated(socket, action_id)}
  end

  @impl true
  def handle_info({:flash, kind, message}, socket) do
    {:noreply, MessageHandlers.handle_flash(socket, kind, message)}
  end

  @impl true
  def handle_info(:reload_actions, socket) do
    {:noreply, MessageHandlers.handle_reload_actions(socket)}
  end

  @impl true
  def handle_info({:turn_advanced, payload}, socket) do
    {:noreply, MessageHandlers.handle_turn_advanced(socket, payload)}
  end

  @impl true
  def handle_info({:catch_up_started, payload}, socket) do
    {:noreply, MessageHandlers.handle_catch_up_started(socket, payload)}
  end

  @impl true
  def handle_info({:catch_up_ended, payload}, socket) do
    {:noreply, MessageHandlers.handle_catch_up_ended(socket, payload)}
  end

  @impl true
  def handle_info({:row_locked, payload}, socket) do
    {:noreply, MessageHandlers.handle_row_locked(socket, payload)}
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
          |> DataLoaders.load_scoring_data(updated_session, participant)
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

  @impl true
  def handle_event("start_workshop", _params, socket) do
    EventHandlers.handle_start_workshop(socket)
  end

  @impl true
  def handle_event("intro_next", _params, socket) do
    EventHandlers.handle_intro_next(socket)
  end

  @impl true
  def handle_event("intro_prev", _params, socket) do
    EventHandlers.handle_intro_prev(socket)
  end

  @impl true
  def handle_event("skip_intro", _params, socket) do
    EventHandlers.handle_skip_intro(socket)
  end

  @impl true
  def handle_event("continue_to_scoring", _params, socket) do
    EventHandlers.handle_continue_to_scoring(socket)
  end

  @impl true
  def handle_event("select_score", params, socket) do
    EventHandlers.handle_select_score(socket, params)
  end

  @impl true
  def handle_event("submit_score", _params, socket) do
    EventHandlers.handle_submit_score(socket)
  end

  @impl true
  def handle_event("complete_turn", _params, socket) do
    EventHandlers.handle_complete_turn(socket)
  end

  @impl true
  def handle_event("skip_turn", _params, socket) do
    EventHandlers.handle_skip_turn(socket)
  end

  @impl true
  def handle_event("mark_ready", _params, socket) do
    EventHandlers.handle_mark_ready(socket)
  end

  @impl true
  def handle_event("toggle_facilitator_tips", _params, socket) do
    EventHandlers.handle_toggle_facilitator_tips(socket)
  end

  @impl true
  def handle_event("toggle_notes", _params, socket) do
    EventHandlers.handle_toggle_notes(socket)
  end

  @impl true
  def handle_event("update_note_input", %{"note" => value}, socket) do
    EventHandlers.handle_update_note_input(socket, value)
  end

  @impl true
  def handle_event("add_note", _params, socket) do
    EventHandlers.handle_add_note(socket)
  end

  @impl true
  def handle_event("delete_note", %{"id" => note_id}, socket) do
    EventHandlers.handle_delete_note(socket, note_id)
  end

  @impl true
  def handle_event("continue_past_transition", _params, socket) do
    EventHandlers.handle_continue_past_transition(socket)
  end

  @impl true
  def handle_event("next_question", _params, socket) do
    EventHandlers.handle_next_question(socket)
  end

  @impl true
  def handle_event("continue_to_actions", _params, socket) do
    EventHandlers.handle_continue_to_actions(socket)
  end

  @impl true
  def handle_event("continue_to_wrapup", _params, socket) do
    EventHandlers.handle_continue_to_wrapup(socket)
  end

  @impl true
  def handle_event("delete_action", %{"id" => action_id}, socket) do
    EventHandlers.handle_delete_action(socket, action_id)
  end

  @impl true
  def handle_event("finish_workshop", _params, socket) do
    EventHandlers.handle_finish_workshop(socket)
  end

  @impl true
  def handle_event("go_back", _params, socket) do
    EventHandlers.handle_go_back(socket)
  end

  @impl true
  def handle_event("toggle_export_modal", _params, socket) do
    EventHandlers.handle_toggle_export_modal(socket)
  end

  @impl true
  def handle_event("close_export_modal", _params, socket) do
    EventHandlers.handle_close_export_modal(socket)
  end

  @impl true
  def handle_event("select_export_content", %{"content" => content}, socket) do
    EventHandlers.handle_select_export_content(socket, content)
  end

  @impl true
  def handle_event("export", %{"format" => format}, socket) do
    EventHandlers.handle_export(socket, format)
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
            ready_count={@ready_count}
            eligible_participant_count={@eligible_participant_count}
            all_ready={@all_ready}
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
end
