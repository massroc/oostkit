defmodule WorkgroupPulseWeb.SessionLive.Show do
  @moduledoc """
  Main workshop LiveView - handles the full workshop flow.
  """
  use WorkgroupPulseWeb, :live_view

  alias WorkgroupPulse.Sessions
  alias WorkgroupPulseWeb.SessionLive.Components.ActionsComponent
  alias WorkgroupPulseWeb.SessionLive.Components.CompletedComponent
  alias WorkgroupPulseWeb.SessionLive.Components.IntroComponent
  alias WorkgroupPulseWeb.SessionLive.Components.LobbyComponent
  alias WorkgroupPulseWeb.SessionLive.Components.ScoringComponent
  alias WorkgroupPulseWeb.SessionLive.Components.SummaryComponent
  alias WorkgroupPulseWeb.SessionLive.Handlers.EventHandlers
  alias WorkgroupPulseWeb.SessionLive.Handlers.MessageHandlers
  alias WorkgroupPulseWeb.SessionLive.Helpers.DataLoaders
  alias WorkgroupPulseWeb.SessionLive.TimerHandler

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
     |> assign(active_sheet: :main)
     |> assign(note_input: "")
     |> assign(show_export_modal: false)
     |> assign(export_content: "all")
     |> TimerHandler.init_timer_assigns()
     |> DataLoaders.load_scoring_data(workshop_session, participant)
     |> DataLoaders.load_summary_data(workshop_session)
     |> DataLoaders.load_actions_data(workshop_session)
     |> TimerHandler.maybe_start_timer()}
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
  def handle_info({:participants_ready_reset, _payload}, socket) do
    {:noreply, MessageHandlers.handle_participants_ready_reset(socket)}
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
  def handle_info({:row_locked, payload}, socket) do
    {:noreply, MessageHandlers.handle_row_locked(socket, payload)}
  end

  # Handle timer tick for facilitator timer countdown
  @impl true
  def handle_info(:timer_tick, socket) do
    TimerHandler.handle_timer_tick(socket)
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
  def handle_event("edit_my_score", _params, socket) do
    EventHandlers.handle_edit_my_score(socket)
  end

  @impl true
  def handle_event("close_score_overlay", _params, socket) do
    EventHandlers.handle_close_score_overlay(socket)
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
  def handle_event("focus_sheet", %{"sheet" => sheet}, socket) do
    EventHandlers.handle_focus_sheet(socket, String.to_existing_atom(sheet))
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
    <div id="session-analytics" phx-hook="PostHogTracker" class="flex flex-col h-full">
      {render_facilitator_timer(assigns)}
      <!-- App Header (no session name during workshop phases) -->
      <.app_header session_name={
        if @session.state in ["scoring", "summary", "actions", "completed"],
          do: nil,
          else: session_display_name(@session)
      } />
      <!-- Main Content Area -->
      <div class="flex-1 overflow-hidden relative">
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
              my_turn_locked={@my_turn_locked}
              scores_revealed={@scores_revealed}
              score_count={@score_count}
              active_participant_count={@active_participant_count}
              show_mid_transition={@show_mid_transition}
              show_facilitator_tips={@show_facilitator_tips}
              question_notes={@question_notes}
              active_sheet={@active_sheet}
              note_input={@note_input}
              ready_count={@ready_count}
              eligible_participant_count={@eligible_participant_count}
              all_ready={@all_ready}
              participant_was_skipped={@participant_was_skipped}
              all_questions={(@template && @template.questions) || []}
              all_questions_scores={@all_questions_scores || %{}}
              show_score_overlay={@show_score_overlay || false}
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
      <!-- Sheet Strip (only show during scoring and later phases) -->
      <%= if @session.state in ["scoring", "summary", "actions", "completed"] do %>
        <.sheet_strip
          current={sheet_index(@session)}
          total={sheet_total(@session, assigns)}
          has_notes={@session.state == "scoring"}
        />
      <% end %>
      <!-- Floating Action Buttons (scoring phase) -->
      <%= if @session.state == "scoring" and not @show_mid_transition do %>
        <div class="fixed bottom-[60px] right-5 z-50 flex flex-col items-end gap-2">
          <!-- Ready count message (facilitator only, after scores revealed) -->
          <%= if @participant.is_facilitator and @scores_revealed do %>
            <div class="bg-surface-sheet rounded-lg px-3 py-2 shadow-md text-sm font-brand">
              <%= if @all_ready do %>
                <span class="text-traffic-green">✓</span>
                <span class="text-ink-blue/70">All participants ready</span>
              <% else %>
                <span class="text-ink-blue/70">
                  {@ready_count}/{@eligible_participant_count} ready
                </span>
              <% end %>
            </div>
          <% end %>
          
    <!-- Button row -->
          <div class="flex gap-2">
            <!-- Back button (facilitator only, after Q1) -->
            <%= if @participant.is_facilitator and @session.current_question_index > 0 do %>
              <button
                phx-click="go_back"
                class="btn-workshop btn-workshop-secondary"
              >
                ← Back
              </button>
            <% end %>
            
    <!-- Skip button (facilitator only, when someone else is scoring and hasn't submitted) -->
            <%= if @participant.is_facilitator and not @scores_revealed and not @current_turn_has_score and not (@is_my_turn and not @my_turn_locked) do %>
              <button
                phx-click="skip_turn"
                class="btn-workshop btn-workshop-secondary"
              >
                Skip Turn
              </button>
            <% end %>
            
    <!-- Done button (only during my turn, after score submitted) -->
            <%= if @is_my_turn and not @my_turn_locked and @has_submitted do %>
              <button
                phx-click="complete_turn"
                class="btn-workshop btn-workshop-primary"
              >
                Done →
              </button>
            <% end %>
            
    <!-- Next/Continue button (facilitator only, after scores revealed) -->
            <%= if @participant.is_facilitator and @scores_revealed do %>
              <button
                phx-click="next_question"
                disabled={not @all_ready}
                class={[
                  "btn-workshop",
                  if(@all_ready,
                    do: "btn-workshop-primary",
                    else: "btn-workshop-secondary opacity-50 cursor-not-allowed"
                  )
                ]}
              >
                <%= if @session.current_question_index + 1 >= @total_questions do %>
                  Continue to Summary →
                <% else %>
                  Next Question →
                <% end %>
              </button>
            <% end %>
            
    <!-- Ready button (non-facilitator, after scores revealed) -->
            <%= if not @participant.is_facilitator and @scores_revealed and not @participant_was_skipped do %>
              <%= if @participant.is_ready do %>
                <div class="btn-workshop btn-workshop-secondary opacity-70 cursor-default">
                  <span class="text-traffic-green">✓</span> Ready
                </div>
              <% else %>
                <button
                  phx-click="mark_ready"
                  class="btn-workshop btn-workshop-primary"
                >
                  I'm Ready
                </button>
              <% end %>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp session_display_name(session) do
    # Session name comes from the template, if loaded
    template_name =
      case session.template do
        %{name: name} when is_binary(name) and name != "" -> name
        _ -> nil
      end

    if template_name do
      "#{template_name}"
    else
      "Six Criteria Assessment"
    end
  end

  defp sheet_index(session) do
    case session.state do
      "scoring" -> session.current_question_index
      "summary" -> 0
      "actions" -> 0
      "completed" -> 0
      _ -> 0
    end
  end

  defp sheet_total(session, assigns) do
    case session.state do
      "scoring" -> assigns[:total_questions] || 8
      _ -> 1
    end
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
