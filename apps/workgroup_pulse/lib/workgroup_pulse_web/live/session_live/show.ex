defmodule WorkgroupPulseWeb.SessionLive.Show do
  @moduledoc """
  Main workshop LiveView - handles the full workshop flow.
  """
  use WorkgroupPulseWeb, :live_view

  alias WorkgroupPulse.Sessions
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
     |> assign(carousel_index: initial_carousel_index(workshop_session.state))
     |> assign(show_mid_transition: false)
     |> assign(show_criterion_popup: nil)
     |> assign(note_input: "")
     |> assign(action_input: "")
     |> assign(notes_revealed: false)
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
  def handle_event("carousel_navigate", %{"index" => index, "carousel" => carousel}, socket) do
    EventHandlers.handle_carousel_navigate(socket, carousel, index)
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
  def handle_event("show_criterion_info", %{"index" => index}, socket) do
    EventHandlers.handle_show_criterion_info(socket, String.to_integer(index))
  end

  @impl true
  def handle_event("close_criterion_info", _params, socket) do
    EventHandlers.handle_close_criterion_info(socket)
  end

  @impl true
  def handle_event("focus_sheet", %{"sheet" => sheet}, socket) do
    EventHandlers.handle_focus_sheet(socket, String.to_existing_atom(sheet))
  end

  @impl true
  def handle_event("reveal_notes", _params, socket) do
    EventHandlers.handle_reveal_notes(socket)
  end

  @impl true
  def handle_event("hide_notes", _params, socket) do
    EventHandlers.handle_hide_notes(socket)
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
  def handle_event("continue_to_wrapup", _params, socket) do
    EventHandlers.handle_continue_to_wrapup(socket)
  end

  @impl true
  def handle_event("update_action_input", %{"action" => value}, socket) do
    EventHandlers.handle_update_action_input(socket, value)
  end

  @impl true
  def handle_event("add_action", _params, socket) do
    EventHandlers.handle_add_action(socket)
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
        if @session.state == "lobby",
          do: session_display_name(@session),
          else: nil
      } />
      <!-- Main Content Area -->
      <div class="flex-1 relative">
        {render_phase_carousel(assigns)}
      </div>
      <!-- Notes Side Panel (fixed to right edge of viewport) -->
      <%= if @session.state in ["scoring", "summary", "completed"] do %>
        {render_notes_panel(assigns)}
      <% end %>
      <!-- Floating Action Buttons — fixed to viewport, aligned to sheet width -->
      {render_floating_buttons(assigns)}
    </div>
    """
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # Floating Action Buttons — viewport-fixed, aligned to 720px sheet width
  # ═══════════════════════════════════════════════════════════════════════════

  defp render_floating_buttons(assigns) do
    ~H"""
    <%= case @session.state do %>
      <% "intro" -> %>
        <%= if @carousel_index in 0..3 do %>
          <div class="fixed bottom-10 z-50 left-1/2 -translate-x-1/2 w-[720px] px-6 pointer-events-none">
            <div class="pointer-events-auto flex justify-end items-center gap-3">
              <%= if @carousel_index == 0 do %>
                <button
                  phx-click="skip_intro"
                  class="text-ink-blue/50 hover:text-ink-blue/70 text-sm transition-colors font-brand"
                >
                  Skip intro
                </button>
              <% end %>
              <%= if @carousel_index < 3 do %>
                <button phx-click="intro_next" class="btn-workshop btn-workshop-primary">
                  Next →
                </button>
              <% else %>
                <button phx-click="continue_to_scoring" class="btn-workshop btn-workshop-primary">
                  Next →
                </button>
              <% end %>
            </div>
          </div>
        <% end %>
      <% "scoring" -> %>
        <%= if @carousel_index == 4 and not @show_mid_transition do %>
          <div class="fixed bottom-10 z-50 left-1/2 -translate-x-1/2 w-[720px] px-5 pointer-events-none">
            <div class="pointer-events-auto flex justify-end items-center gap-2">
              <!-- Ready count (facilitator only, after scores revealed) -->
              <%= if @participant.is_facilitator and @scores_revealed do %>
                <div class="text-sm font-brand mr-auto bg-surface-sheet rounded-lg px-3 py-2 shadow-md">
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
              <!-- Back (facilitator, after Q1) -->
              <%= if @participant.is_facilitator and @session.current_question_index > 0 do %>
                <button phx-click="go_back" class="btn-workshop btn-workshop-secondary">
                  ← Back
                </button>
              <% end %>
              <!-- Skip turn (facilitator, when someone else is scoring) -->
              <%= if @participant.is_facilitator and not @scores_revealed and not @current_turn_has_score and not (@is_my_turn and not @my_turn_locked) do %>
                <button phx-click="skip_turn" class="btn-workshop btn-workshop-secondary">
                  Skip Turn
                </button>
              <% end %>
              <!-- Done (my turn, after submitting) -->
              <%= if @is_my_turn and not @my_turn_locked and @has_submitted do %>
                <button phx-click="complete_turn" class="btn-workshop btn-workshop-primary">
                  Done →
                </button>
              <% end %>
              <!-- Next question (facilitator, after scores revealed) -->
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
              <!-- Ready (non-facilitator, after scores revealed) -->
              <%= if not @participant.is_facilitator and @scores_revealed and not @participant_was_skipped do %>
                <%= if @participant.is_ready do %>
                  <div class="btn-workshop btn-workshop-secondary opacity-70 cursor-default">
                    <span class="text-traffic-green">✓</span> Ready
                  </div>
                <% else %>
                  <button phx-click="mark_ready" class="btn-workshop btn-workshop-primary">
                    I'm Ready
                  </button>
                <% end %>
              <% end %>
            </div>
          </div>
        <% end %>
      <% "summary" -> %>
        <%= if @carousel_index == 5 do %>
          <div class="fixed bottom-10 z-50 left-1/2 -translate-x-1/2 w-[720px] px-6 pointer-events-none">
            <div class="pointer-events-auto flex justify-end items-center gap-2">
              <%= if @participant.is_facilitator do %>
                <button phx-click="go_back" class="btn-workshop btn-workshop-secondary">
                  ← Back
                </button>
                <button phx-click="continue_to_wrapup" class="btn-workshop btn-workshop-primary">
                  Continue to Wrap-Up →
                </button>
              <% else %>
                <span class="text-ink-blue/60 font-brand text-sm bg-surface-sheet rounded-lg px-3 py-2 shadow-md">
                  Waiting for facilitator to continue...
                </span>
              <% end %>
            </div>
          </div>
        <% end %>
      <% "completed" -> %>
        <%= if @carousel_index == 6 do %>
          <div class="fixed bottom-10 z-50 left-1/2 -translate-x-1/2 w-[720px] px-6 pointer-events-none">
            <div class="pointer-events-auto flex justify-end items-center gap-2">
              <%= if @participant.is_facilitator do %>
                <button phx-click="finish_workshop" class="btn-workshop btn-workshop-primary">
                  Finish Workshop
                </button>
              <% else %>
                <span class="text-ink-blue/60 font-brand text-sm bg-surface-sheet rounded-lg px-3 py-2 shadow-md">
                  Waiting for facilitator to finish...
                </span>
              <% end %>
            </div>
          </div>
        <% end %>
      <% _ -> %>
    <% end %>
    """
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # Phase carousel — universal layout for all phases
  # ═══════════════════════════════════════════════════════════════════════════

  defp render_phase_carousel(assigns) do
    ~H"""
    <%= if @session.state == "lobby" do %>
      <div class="sheet-carousel">
        <div class="carousel-slide active">
          <LobbyComponent.render
            session={@session}
            participant={@participant}
            participants={@participants}
          />
        </div>
      </div>
    <% else %>
      {render_unified_carousel(assigns)}
    <% end %>
    """
  end

  defp render_unified_carousel(assigns) do
    ~H"""
    <div
      id="workshop-carousel"
      phx-hook="SheetCarousel"
      data-index={@carousel_index}
      class="sheet-carousel"
    >
      <div class="embla__viewport">
        <div class="embla__container">
          <%!-- Slides 0-3: intro slides (always rendered) --%>
          <div class="carousel-slide">
            <IntroComponent.slide_welcome />
          </div>
          <div class="carousel-slide">
            <IntroComponent.slide_how_it_works />
          </div>
          <div class="carousel-slide">
            <IntroComponent.slide_balance_scale />
          </div>
          <div class="carousel-slide">
            <IntroComponent.slide_safe_space />
          </div>

          <%!-- Slide 4: scoring grid (when scoring/summary/completed) --%>
          <%= if @session.state in ["scoring", "summary", "completed"] do %>
            <div class="carousel-slide">
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
                show_criterion_popup={@show_criterion_popup}
                ready_count={@ready_count}
                eligible_participant_count={@eligible_participant_count}
                all_ready={@all_ready}
                participant_was_skipped={@participant_was_skipped}
                all_questions={(@template && @template.questions) || []}
                all_questions_scores={@all_questions_scores || %{}}
                show_score_overlay={@show_score_overlay || false}
              />
            </div>
          <% end %>

          <%!-- Slide 5: summary (when summary/completed) --%>
          <%= if @session.state in ["summary", "completed"] do %>
            <div class="carousel-slide">
              <SummaryComponent.render
                session={@session}
                participant={@participant}
                participants={@participants}
                scores_summary={@scores_summary}
                individual_scores={@individual_scores}
                notes_by_question={@notes_by_question}
              />
            </div>
          <% end %>

          <%!-- Slide 6: wrap-up (when completed) --%>
          <%= if @session.state == "completed" do %>
            <div class="carousel-slide">
              <CompletedComponent.render
                session={@session}
                participant={@participant}
                scores_summary={@scores_summary}
                strengths={@strengths}
                concerns={@concerns}
                action_count={@action_count}
                show_export_modal={@show_export_modal}
                export_content={@export_content}
              />
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # Notes/Actions Side Panel (fixed to right edge of viewport)
  # ═══════════════════════════════════════════════════════════════════════════

  defp render_notes_panel(assigns) do
    ~H"""
    <%= if @notes_revealed do %>
      <div class="fixed top-[52px] left-0 right-0 bottom-0 z-10" phx-click="hide_notes"></div>
      <div class="fixed top-[52px] right-0 bottom-0 w-[480px] z-20 py-6 pr-4">
        {render_notes_content(assigns)}
      </div>
    <% else %>
      <%= if @carousel_index == 4 do %>
        <button
          phx-click="reveal_notes"
          class="fixed top-[52px] right-0 bottom-0 w-[40px] z-20 py-6 cursor-pointer group"
        >
          <.sheet
            variant={:secondary}
            class="h-full w-full flex items-center justify-center shadow-sheet"
            style="transform: rotate(0deg)"
          >
            <span class="font-workshop text-sm font-bold text-ink-blue/60 group-hover:text-ink-blue writing-vertical-rl">
              Notes
            </span>
          </.sheet>
        </button>
      <% end %>
    <% end %>
    """
  end

  defp render_notes_content(assigns) do
    ~H"""
    <.sheet
      variant={:secondary}
      class="notes-panel p-4 w-full h-full shadow-sheet"
      style="transform: rotate(0deg)"
    >
      <!-- Notes section -->
      <div class="mb-6">
        <div class="mb-2">
          <div class="font-workshop text-lg font-bold text-ink-blue underline underline-offset-[3px] decoration-[1.5px] decoration-ink-blue/20 opacity-85">
            Notes
            <%= if length(@question_notes) > 0 do %>
              <span class="text-sm font-normal text-ink-blue/50 ml-1">
                ({length(@question_notes)})
              </span>
            <% end %>
          </div>
        </div>

        <form phx-submit="add_note" class="mb-2">
          <input
            type="text"
            name="note"
            value={@note_input}
            phx-change="update_note_input"
            phx-debounce="300"
            placeholder="Add a note..."
            class="w-full bg-surface-sheet border border-ink-blue/10 rounded-lg px-3 py-2 text-sm text-ink-blue placeholder-ink-blue/40 focus:outline-none focus:border-accent-purple focus:ring-1 focus:ring-accent-purple font-workshop"
          />
        </form>

        <div class="space-y-1.5">
          <%= if length(@question_notes) > 0 do %>
            <%= for note <- @question_notes do %>
              <div class="bg-surface-sheet/50 rounded p-2 text-sm group">
                <div class="flex justify-between items-start gap-1">
                  <p class="font-workshop text-ink-blue flex-1">{note.content}</p>
                  <button
                    type="button"
                    phx-click="delete_note"
                    phx-value-id={note.id}
                    class="text-ink-blue/30 hover:text-traffic-red transition-colors opacity-0 group-hover:opacity-100 shrink-0"
                  >
                    ✕
                  </button>
                </div>
              </div>
            <% end %>
          <% else %>
            <p class="text-ink-blue/50 text-sm italic font-workshop">
              No notes yet. Type above to add one.
            </p>
          <% end %>
        </div>
      </div>
      <!-- Actions section -->
      <div class="border-t border-ink-blue/10 pt-4">
        <div class="mb-2">
          <div class="font-workshop text-lg font-bold text-ink-blue underline underline-offset-[3px] decoration-[1.5px] decoration-ink-blue/20 opacity-85">
            Actions
            <%= if @action_count > 0 do %>
              <span class="text-sm font-normal text-ink-blue/50 ml-1">
                ({@action_count})
              </span>
            <% end %>
          </div>
        </div>

        <form phx-submit="add_action" class="mb-2">
          <input
            type="text"
            name="action"
            value={@action_input}
            phx-change="update_action_input"
            phx-debounce="300"
            placeholder="Add an action..."
            class="w-full bg-surface-sheet border border-ink-blue/10 rounded-lg px-3 py-2 text-sm text-ink-blue placeholder-ink-blue/40 focus:outline-none focus:border-accent-purple focus:ring-1 focus:ring-accent-purple font-workshop"
          />
        </form>

        <div class="space-y-1.5">
          <%= if @action_count > 0 do %>
            <%= for action <- @all_actions do %>
              <div class="bg-surface-sheet/50 rounded p-2 text-sm group">
                <div class="flex justify-between items-start gap-1">
                  <p class="font-workshop text-ink-blue flex-1">{action.description}</p>
                  <button
                    type="button"
                    phx-click="delete_action"
                    phx-value-id={action.id}
                    class="text-ink-blue/30 hover:text-traffic-red transition-colors opacity-0 group-hover:opacity-100 shrink-0"
                  >
                    ✕
                  </button>
                </div>
              </div>
            <% end %>
          <% else %>
            <p class="text-ink-blue/50 text-sm italic font-workshop">
              No actions yet. Type above to add one.
            </p>
          <% end %>
        </div>
      </div>
    </.sheet>
    """
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # Helper functions
  # ═══════════════════════════════════════════════════════════════════════════

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
