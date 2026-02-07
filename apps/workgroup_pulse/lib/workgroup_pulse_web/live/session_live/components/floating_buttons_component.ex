defmodule WorkgroupPulseWeb.SessionLive.Components.FloatingButtonsComponent do
  @moduledoc """
  Renders phase-specific floating action buttons fixed to the viewport.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :carousel_index, :integer, required: true
  attr :show_mid_transition, :boolean, default: false
  attr :scores_revealed, :boolean, default: false
  attr :all_ready, :boolean, default: false
  attr :ready_count, :integer, default: 0
  attr :eligible_participant_count, :integer, default: 0
  attr :is_my_turn, :boolean, default: false
  attr :my_turn_locked, :boolean, default: false
  attr :has_submitted, :boolean, default: false
  attr :current_turn_has_score, :boolean, default: false
  attr :total_questions, :integer, default: 0
  attr :participant_was_skipped, :boolean, default: false

  def render(assigns) do
    ~H"""
    <%= case @session.state do %>
      <% "intro" -> %>
        {render_intro_buttons(assigns)}
      <% "scoring" -> %>
        {render_scoring_buttons(assigns)}
      <% "summary" -> %>
        {render_summary_buttons(assigns)}
      <% "completed" -> %>
        {render_completed_buttons(assigns)}
      <% _ -> %>
    <% end %>
    """
  end

  defp render_intro_buttons(assigns) do
    ~H"""
    <%= if @carousel_index in 0..3 do %>
      <div class="fixed bottom-10 z-50 left-1/2 -translate-x-1/2 w-[720px] px-6 pointer-events-none">
        <div class="flex justify-between items-center">
          <%!-- Left: Back button or Skip intro --%>
          <div class="flex items-center gap-3">
            <%= if @carousel_index == 0 do %>
              <button
                phx-click="skip_intro"
                class="pointer-events-auto text-ink-blue/50 hover:text-ink-blue/70 text-sm transition-colors font-brand"
              >
                Skip intro
              </button>
            <% else %>
              <button phx-click="intro_prev" class="pointer-events-auto btn-workshop btn-workshop-secondary">
                ← Back
              </button>
            <% end %>
          </div>
          <%!-- Center: Progress dots --%>
          <div class="flex items-center gap-2">
            <%= for i <- 0..3 do %>
              <div class={[
                "w-2 h-2 rounded-full transition-colors",
                if(i == @carousel_index,
                  do: "bg-accent-purple",
                  else: "bg-ink-blue/20"
                )
              ]} />
            <% end %>
          </div>
          <%!-- Right: Next / Start Scoring --%>
          <div class="flex items-center">
            <%= if @carousel_index < 3 do %>
              <button phx-click="intro_next" class="pointer-events-auto btn-workshop btn-workshop-primary">
                Next →
              </button>
            <% else %>
              <button phx-click="continue_to_scoring" class="pointer-events-auto btn-workshop btn-workshop-primary">
                Start Scoring →
              </button>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp render_scoring_buttons(assigns) do
    ~H"""
    <%= if @carousel_index == 4 and not @show_mid_transition do %>
      <div class="fixed bottom-10 z-50 left-1/2 -translate-x-1/2 w-[720px] px-5 pointer-events-none">
        <div class="flex justify-end items-center gap-2">
          <!-- Ready count (facilitator only, after scores revealed) -->
          <%= if @participant.is_facilitator and @scores_revealed do %>
            <div class="pointer-events-auto text-sm font-brand mr-auto bg-surface-sheet rounded-lg px-3 py-2 shadow-md">
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
            <button phx-click="go_back" class="pointer-events-auto btn-workshop btn-workshop-secondary">
              ← Back
            </button>
          <% end %>
          <!-- Skip turn (facilitator, when someone else is scoring) -->
          <%= if @participant.is_facilitator and not @scores_revealed and not @current_turn_has_score and not (@is_my_turn and not @my_turn_locked) do %>
            <button phx-click="skip_turn" class="pointer-events-auto btn-workshop btn-workshop-secondary">
              Skip Turn
            </button>
          <% end %>
          <!-- Done (my turn, after submitting) -->
          <%= if @is_my_turn and not @my_turn_locked and @has_submitted do %>
            <button phx-click="complete_turn" class="pointer-events-auto btn-workshop btn-workshop-primary">
              Done →
            </button>
          <% end %>
          <!-- Next question (facilitator, after scores revealed) -->
          <%= if @participant.is_facilitator and @scores_revealed do %>
            <button
              phx-click="next_question"
              disabled={not @all_ready}
              class={[
                "pointer-events-auto btn-workshop",
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
              <div class="pointer-events-auto btn-workshop btn-workshop-secondary opacity-70 cursor-default">
                <span class="text-traffic-green">✓</span> Ready
              </div>
            <% else %>
              <button phx-click="mark_ready" class="pointer-events-auto btn-workshop btn-workshop-primary">
                I'm Ready
              </button>
            <% end %>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp render_summary_buttons(assigns) do
    ~H"""
    <%= if @carousel_index == 5 do %>
      <div class="fixed bottom-10 z-50 left-1/2 -translate-x-1/2 w-[720px] px-6 pointer-events-none">
        <div class="flex justify-end items-center gap-2">
          <%= if @participant.is_facilitator do %>
            <button phx-click="go_back" class="pointer-events-auto btn-workshop btn-workshop-secondary">
              ← Back
            </button>
            <button phx-click="continue_to_wrapup" class="pointer-events-auto btn-workshop btn-workshop-primary">
              Continue to Wrap-Up →
            </button>
          <% else %>
            <span class="pointer-events-auto text-ink-blue/60 font-brand text-sm bg-surface-sheet rounded-lg px-3 py-2 shadow-md">
              Waiting for facilitator to continue...
            </span>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp render_completed_buttons(assigns) do
    ~H"""
    <%= if @carousel_index == 6 do %>
      <div class="fixed bottom-10 z-50 left-1/2 -translate-x-1/2 w-[720px] px-6 pointer-events-none">
        <div class="flex justify-end items-center gap-2">
          <%= if @participant.is_facilitator do %>
            <button phx-click="finish_workshop" class="pointer-events-auto btn-workshop btn-workshop-primary">
              Finish Workshop
            </button>
          <% else %>
            <span class="pointer-events-auto text-ink-blue/60 font-brand text-sm bg-surface-sheet rounded-lg px-3 py-2 shadow-md">
              Waiting for facilitator to finish...
            </span>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end
end
