defmodule WorkgroupPulseWeb.SessionLive.Show do
  @moduledoc """
  Main workshop LiveView - handles the full workshop flow.
  """
  use WorkgroupPulseWeb, :live_view

  alias WorkgroupPulse.Sessions
  alias WorkgroupPulseWeb.SessionLive.Components.CompletedComponent
  alias WorkgroupPulseWeb.SessionLive.Components.FloatingButtonsComponent
  alias WorkgroupPulseWeb.SessionLive.Components.IntroComponent
  alias WorkgroupPulseWeb.SessionLive.Components.LobbyComponent
  alias WorkgroupPulseWeb.SessionLive.Components.NotesPanelComponent
  alias WorkgroupPulseWeb.SessionLive.Components.ScoreOverlayComponent
  alias WorkgroupPulseWeb.SessionLive.Components.ScoringComponent
  alias WorkgroupPulseWeb.SessionLive.Components.SummaryComponent
  alias WorkgroupPulseWeb.SessionLive.Handlers.ContentHandlers
  alias WorkgroupPulseWeb.SessionLive.Handlers.MessageHandlers
  alias WorkgroupPulseWeb.SessionLive.Handlers.NavigationHandlers
  alias WorkgroupPulseWeb.SessionLive.Handlers.ScoringHandlers
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
     |> assign(carousel_index: initial_carousel_index(workshop_session.state))
     |> assign(show_mid_transition: false)
     |> assign(show_criterion_popup: nil)
     |> assign(show_discuss_prompt: false)
     |> assign(show_team_discuss_prompt: false)
     |> assign(note_input: "")
     |> assign(action_input: "")
     |> assign(notes_revealed: false)
     |> assign(show_export_modal: false)
     |> assign(export_report_type: "full")
     |> TimerHandler.init_timer_assigns()
     |> DataLoaders.load_scoring_data(workshop_session, participant)
     |> DataLoaders.load_summary_data(workshop_session)
     |> DataLoaders.load_actions_data(workshop_session)
     |> TimerHandler.maybe_start_timer(), layout: {WorkgroupPulseWeb.Layouts, :session}}
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # PubSub message handlers
  # ═══════════════════════════════════════════════════════════════════════════

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
  def handle_info(:note_updated, socket) do
    {:noreply, MessageHandlers.handle_note_updated(socket)}
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
  def handle_info({:turn_advanced, payload}, socket) do
    {:noreply, MessageHandlers.handle_turn_advanced(socket, payload)}
  end

  @impl true
  def handle_info({:row_locked, payload}, socket) do
    {:noreply, MessageHandlers.handle_row_locked(socket, payload)}
  end

  @impl true
  def handle_info(:timer_tick, socket) do
    TimerHandler.handle_timer_tick(socket)
  end

  @impl true
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # Navigation events
  # ═══════════════════════════════════════════════════════════════════════════

  @impl true
  def handle_event("start_workshop", _params, socket),
    do: NavigationHandlers.handle_start_workshop(socket)

  @impl true
  def handle_event("intro_next", _params, socket),
    do: NavigationHandlers.handle_intro_next(socket)

  @impl true
  def handle_event("intro_prev", _params, socket),
    do: NavigationHandlers.handle_intro_prev(socket)

  @impl true
  def handle_event(event, _params, socket) when event in ~w(skip_intro continue_to_scoring),
    do: NavigationHandlers.handle_skip_intro(socket)

  @impl true
  def handle_event("carousel_navigate", %{"index" => index, "carousel" => carousel}, socket),
    do: NavigationHandlers.handle_carousel_navigate(socket, carousel, index)

  @impl true
  def handle_event("continue_past_transition", _params, socket),
    do: NavigationHandlers.handle_continue_past_transition(socket)

  @impl true
  def handle_event("next_question", _params, socket),
    do: NavigationHandlers.handle_next_question(socket)

  @impl true
  def handle_event("continue_to_wrapup", _params, socket),
    do: NavigationHandlers.handle_continue_to_wrapup(socket)

  @impl true
  def handle_event("finish_workshop", _params, socket),
    do: NavigationHandlers.handle_finish_workshop(socket)

  @impl true
  def handle_event("go_back", _params, socket),
    do: NavigationHandlers.handle_go_back(socket)

  # ═══════════════════════════════════════════════════════════════════════════
  # Scoring events
  # ═══════════════════════════════════════════════════════════════════════════

  @impl true
  def handle_event("select_score", params, socket),
    do: ScoringHandlers.handle_select_score(socket, params)

  @impl true
  def handle_event("submit_score", _params, socket),
    do: ScoringHandlers.handle_submit_score(socket)

  @impl true
  def handle_event("edit_my_score", _params, socket),
    do: ScoringHandlers.handle_edit_my_score(socket)

  @impl true
  def handle_event("close_score_overlay", _params, socket),
    do: ScoringHandlers.handle_close_score_overlay(socket)

  @impl true
  def handle_event("complete_turn", _params, socket),
    do: ScoringHandlers.handle_complete_turn(socket)

  @impl true
  def handle_event("skip_turn", _params, socket),
    do: ScoringHandlers.handle_skip_turn(socket)

  @impl true
  def handle_event("mark_ready", _params, socket),
    do: ScoringHandlers.handle_mark_ready(socket)

  # ═══════════════════════════════════════════════════════════════════════════
  # Content & UI events
  # ═══════════════════════════════════════════════════════════════════════════

  @impl true
  def handle_event("dismiss_discuss_prompt", _params, socket),
    do: ContentHandlers.handle_dismiss_prompt(socket, :show_discuss_prompt)

  @impl true
  def handle_event("dismiss_team_discuss_prompt", _params, socket),
    do: ContentHandlers.handle_dismiss_prompt(socket, :show_team_discuss_prompt)

  @impl true
  def handle_event("show_criterion_info", %{"index" => index}, socket),
    do: ContentHandlers.handle_show_criterion_info(socket, String.to_integer(index))

  @impl true
  def handle_event("close_criterion_info", _params, socket),
    do: ContentHandlers.handle_close_criterion_info(socket)

  @impl true
  def handle_event("focus_sheet", %{"sheet" => sheet}, socket),
    do: ContentHandlers.handle_focus_sheet(socket, String.to_existing_atom(sheet))

  @impl true
  def handle_event("reveal_notes", _params, socket),
    do: ContentHandlers.handle_reveal_notes(socket)

  @impl true
  def handle_event("hide_notes", _params, socket),
    do: ContentHandlers.handle_hide_notes(socket)

  @impl true
  def handle_event("update_note_input", %{"note" => value}, socket),
    do: ContentHandlers.handle_update_note_input(socket, value)

  @impl true
  def handle_event("add_note", %{"note" => content}, socket),
    do: ContentHandlers.handle_add_note(socket, content)

  @impl true
  def handle_event("delete_note", %{"id" => note_id}, socket),
    do: ContentHandlers.handle_delete_note(socket, note_id)

  @impl true
  def handle_event("update_action_input", %{"action" => value}, socket),
    do: ContentHandlers.handle_update_action_input(socket, value)

  @impl true
  def handle_event("add_action", %{"action" => description}, socket),
    do: ContentHandlers.handle_add_action(socket, description)

  @impl true
  def handle_event("delete_action", %{"id" => action_id}, socket),
    do: ContentHandlers.handle_delete_action(socket, action_id)

  @impl true
  def handle_event("toggle_export_modal", _params, socket),
    do: ContentHandlers.handle_toggle_export_modal(socket)

  @impl true
  def handle_event("close_export_modal", _params, socket),
    do: ContentHandlers.handle_close_export_modal(socket)

  @impl true
  def handle_event("select_export_report_type", %{"type" => type}, socket),
    do: ContentHandlers.handle_select_export_report_type(socket, type)

  @impl true
  def handle_event("export", %{"format" => format}, socket),
    do: ContentHandlers.handle_export(socket, format)

  # ═══════════════════════════════════════════════════════════════════════════
  # Render
  # ═══════════════════════════════════════════════════════════════════════════

  @impl true
  def render(assigns) do
    ~H"""
    <div id="session-analytics" phx-hook="PostHogTracker" class="flex flex-col h-full">
      {render_facilitator_timer(assigns)}
      <div class="flex-shrink-0 z-sheet-current">
        <.header_bar
          brand_url={Application.get_env(:workgroup_pulse, :portal_url, "https://oostkit.com")}
          title="Workgroup Pulse"
        />
      </div>
      <!-- Main Content Area -->
      <div class="flex-1 relative">
        {render_phase_carousel(assigns)}
      </div>
      <!-- Scoring overlays rendered outside carousel so position:fixed works -->
      <ScoreOverlayComponent.render
        session={@session}
        is_my_turn={@is_my_turn}
        my_turn_locked={@my_turn_locked}
        show_score_overlay={@show_score_overlay || false}
        show_discuss_prompt={@show_discuss_prompt}
        show_team_discuss_prompt={@show_team_discuss_prompt}
        show_criterion_popup={@show_criterion_popup}
        current_question={@current_question}
        selected_value={@selected_value}
        has_submitted={@has_submitted}
        all_questions={(@template && @template.questions) || []}
      />
      <!-- Notes Side Panel (fixed to right edge of viewport) -->
      <%= if @session.state in ["scoring", "summary", "completed"] do %>
        <NotesPanelComponent.render
          notes_revealed={@notes_revealed}
          carousel_index={@carousel_index}
          question_notes={@question_notes}
          note_input={@note_input}
          all_actions={@all_actions}
          action_count={@action_count}
          action_input={@action_input}
        />
      <% end %>
      <!-- Floating Action Buttons — fixed to viewport, aligned to sheet width -->
      <FloatingButtonsComponent.render
        session={@session}
        participant={@participant}
        carousel_index={@carousel_index}
        show_mid_transition={@show_mid_transition}
        scores_revealed={@scores_revealed}
        all_ready={@all_ready}
        ready_count={@ready_count}
        eligible_participant_count={@eligible_participant_count}
        is_my_turn={@is_my_turn}
        my_turn_locked={@my_turn_locked}
        has_submitted={@has_submitted}
        current_turn_has_score={@current_turn_has_score}
        total_questions={@total_questions}
        participant_was_skipped={@participant_was_skipped}
      />
    </div>
    """
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # Phase carousel — universal layout for all phases
  # ═══════════════════════════════════════════════════════════════════════════

  defp render_phase_carousel(assigns) do
    ~H"""
    <%= if @session.state == "lobby" do %>
      <div id="workshop-carousel" phx-hook="SheetStack" data-index="0" class="sheet-stack">
        <div class="sheet-stack-slide" data-slide="0">
          <LobbyComponent.render
            session={@session}
            participant={@participant}
            participants={@participants}
          />
        </div>
      </div>
    <% else %>
      {render_unified_stack(assigns)}
    <% end %>
    """
  end

  defp render_unified_stack(assigns) do
    ~H"""
    <div
      id="workshop-carousel"
      phx-hook="SheetStack"
      data-index={@carousel_index}
      class="sheet-stack"
    >
      <%!-- Slides 0-3: intro slides (always rendered) --%>
      <div class="sheet-stack-slide" data-slide="0">
        <IntroComponent.slide_welcome />
      </div>
      <div class="sheet-stack-slide" data-slide="1">
        <IntroComponent.slide_how_it_works />
      </div>
      <div class="sheet-stack-slide" data-slide="2">
        <IntroComponent.slide_balance_scale />
      </div>
      <div class="sheet-stack-slide" data-slide="3">
        <IntroComponent.slide_maximal_scale />
      </div>

      <%!-- Slide 4: scoring grid (when scoring/summary/completed) --%>
      <%= if @session.state in ["scoring", "summary", "completed"] do %>
        <div class="sheet-stack-slide" data-slide="4">
          <ScoringComponent.render
            session={@session}
            participant={@participant}
            participants={@participants}
            current_question={@current_question}
            has_submitted={@has_submitted}
            is_my_turn={@is_my_turn}
            current_turn_participant_id={@current_turn_participant_id}
            my_turn_locked={@my_turn_locked}
            show_mid_transition={@show_mid_transition}
            all_questions={(@template && @template.questions) || []}
            all_questions_scores={@all_questions_scores || %{}}
          />
        </div>
      <% end %>

      <%!-- Slide 5: summary (when summary/completed) --%>
      <%= if @session.state in ["summary", "completed"] do %>
        <div class="sheet-stack-slide" data-slide="5">
          <SummaryComponent.render
            session={@session}
            participant={@participant}
            participants={@participants}
            scores_summary={@scores_summary}
            individual_scores={@individual_scores}
            all_questions={
              case @summary_template || @template do
                %{questions: q} -> q
                _ -> []
              end
            }
          />
        </div>
      <% end %>

      <%!-- Slide 6: wrap-up (when completed) --%>
      <%= if @session.state == "completed" do %>
        <div class="sheet-stack-slide" data-slide="6">
          <CompletedComponent.render
            session={@session}
            participant={@participant}
            participants={@participants}
            scores_summary={@scores_summary}
            individual_scores={@individual_scores}
            strengths={@strengths}
            concerns={@concerns}
            all_notes={@all_notes}
            all_actions={@all_actions}
            action_count={@action_count}
            action_input={@action_input}
            show_export_modal={@show_export_modal}
            export_report_type={@export_report_type}
            summary_template={@summary_template}
          />
        </div>
      <% end %>
    </div>
    """
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # Helper functions
  # ═══════════════════════════════════════════════════════════════════════════

  defp initial_carousel_index("scoring"), do: 4
  defp initial_carousel_index("summary"), do: 5
  defp initial_carousel_index("completed"), do: 6
  defp initial_carousel_index(_), do: 0

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
