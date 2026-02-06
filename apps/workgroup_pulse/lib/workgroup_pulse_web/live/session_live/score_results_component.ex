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
    """
  end
end
