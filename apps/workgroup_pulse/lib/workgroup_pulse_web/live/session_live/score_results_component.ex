defmodule WorkgroupPulseWeb.SessionLive.ScoreResultsComponent do
  @moduledoc """
  LiveComponent for displaying score results after reveal.
  Isolates re-renders to just this section when scores change.
  Uses Virtual Wall design with paper-textured styling.

  Notes are now handled by the side sheet in ScoringComponent.
  """
  use WorkgroupPulseWeb, :live_component

  import WorkgroupPulseWeb.SessionLive.ScoreHelpers,
    only: [text_color_class: 1, bg_color_class: 1]

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  # All events are handled by parent LiveView for test compatibility
  # This component is purely for render isolation

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <!-- Results summary with team discussion prompt -->
      <div class="bg-surface-wall/50 rounded-lg p-4">
        <!-- Team discussion prompt -->
        <div class="text-center mb-4">
          <div class="text-traffic-green text-lg font-semibold font-brand">
            Discuss as a team
          </div>
          <p class="text-ink-blue/60 text-sm mt-1">
            Look for variance across the group
          </p>
        </div>
        
    <!-- Individual scores - horizontal boxes -->
        <div class="flex flex-wrap gap-2 justify-center">
          <%= for score <- @all_scores do %>
            <div
              class={[
                "rounded-lg p-2 text-center min-w-[4rem] flex-shrink-0 border",
                bg_color_class(score.color)
              ]}
              title={score.participant_name}
            >
              <div class={["text-xl font-bold font-workshop", text_color_class(score.color)]}>
                <%= if @current_question.scale_type == "balance" and score.value > 0 do %>
                  +
                <% end %>
                {score.value}
              </div>
              <div class="text-xs text-ink-blue/60 truncate max-w-[4rem] font-workshop">
                {score.participant_name}
              </div>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Ready / Next controls -->
      <div class="bg-surface-wall/50 rounded-lg p-4">
        <%= if @participant.is_facilitator do %>
          <div class="flex gap-3">
            <%= if @session.current_question_index > 0 do %>
              <button
                phx-click="go_back"
                class="btn-workshop btn-workshop-secondary"
              >
                ← Back
              </button>
            <% end %>
            <button
              phx-click="next_question"
              disabled={not @all_ready}
              class={[
                "flex-1 btn-workshop",
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
          </div>
          <p class="text-center text-ink-blue/50 text-sm mt-2 font-brand">
            <%= if @all_ready do %>
              All participants ready
            <% else %>
              {@ready_count} of {@eligible_participant_count} participants ready
            <% end %>
          </p>
        <% else %>
          <%= if @participant_was_skipped do %>
            <!-- Skipped participant -->
            <div class="text-center">
              <button
                disabled
                class="w-full btn-workshop btn-workshop-secondary opacity-50 cursor-not-allowed"
              >
                Ready to Continue
              </button>
              <p class="text-ink-blue/50 text-sm mt-2 font-brand">
                You were skipped for this question
              </p>
            </div>
          <% else %>
            <%= if @participant.is_ready do %>
              <div class="text-center text-ink-blue/70 font-brand">
                <span class="text-traffic-green">✓</span> You're ready. Waiting for facilitator...
              </div>
            <% else %>
              <button
                phx-click="mark_ready"
                class="w-full btn-workshop btn-workshop-primary"
              >
                I'm Ready to Continue
              </button>
            <% end %>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
