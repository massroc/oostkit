defmodule WorkgroupPulseWeb.SessionLive.Components.CompletedComponent do
  @moduledoc """
  Renders the wrap-up/completed phase of a workshop session.
  Shows final scores, strengths, concerns, action items, and export options.
  Uses Virtual Wall design with paper-textured sheet.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.SessionLive.ScoreHelpers,
    only: [text_color_class: 1, card_color_class: 1]

  alias WorkgroupPulseWeb.SessionLive.ActionFormComponent
  alias WorkgroupPulseWeb.SessionLive.Components.ExportModalComponent

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :scores_summary, :list, required: true
  attr :strengths, :list, required: true
  attr :concerns, :list, required: true
  attr :all_actions, :list, required: true
  attr :action_count, :integer, required: true
  attr :show_export_modal, :boolean, required: true
  attr :export_content, :string, required: true

  def render(assigns) do
    ~H"""
    <div class="flex items-start justify-center h-full p-6 overflow-auto">
      <!-- Main Sheet -->
      <div
        class="paper-texture rounded-sheet shadow-sheet p-6 max-w-4xl w-full"
        style="transform: rotate(-0.2deg)"
      >
        <div class="relative z-[1]">
          <!-- Header -->
          <div class="text-center mb-6 pb-4 border-b-2 border-ink-blue/10">
            <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-2">
              Workshop Wrap-Up
            </h1>
            <p class="text-ink-blue/70">
              Review key findings and create action items.
            </p>
            <p class="text-sm text-ink-blue/50 mt-2 font-brand">
              Session code: <span class="font-mono text-ink-blue">{@session.code}</span>
            </p>
          </div>
          
    <!-- Score Grid -->
          <div class="bg-surface-wall/50 rounded-lg p-4 mb-6">
            <h2 class="text-sm font-semibold text-ink-blue/60 mb-3 font-brand uppercase tracking-wide">
              All Scores
            </h2>
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <%= for score <- @scores_summary do %>
                <div class={["rounded-lg p-3 text-center border", card_color_class(score.color)]}>
                  <div class="text-xs text-ink-blue/50 mb-1 font-brand">
                    Q{score.question_index + 1}
                  </div>
                  <div class={["text-2xl font-bold font-workshop", text_color_class(score.color)]}>
                    <%= if score.combined_team_value do %>
                      {round(score.combined_team_value)}/10
                    <% else %>
                      —
                    <% end %>
                  </div>
                  <div
                    class="text-xs text-ink-blue/60 truncate mt-1 font-workshop"
                    title={score.title}
                  >
                    {score.title}
                  </div>
                </div>
              <% end %>
            </div>
            <div class="flex items-center justify-center gap-1 text-xs text-ink-blue/40 mt-2 font-brand">
              <span>Combined Team Values</span>
              <span
                class="cursor-help"
                title="Each person's score is graded (green=2, amber=1, red=0), then averaged and scaled to 0-10. 10 = everyone scored well, 0 = everyone scored poorly."
              >
                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </span>
            </div>
          </div>
          
    <!-- Pattern Highlighting -->
          <%= if length(@strengths) > 0 or length(@concerns) > 0 do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <!-- Strengths -->
              <%= if length(@strengths) > 0 do %>
                <div class="bg-green-50 border border-traffic-green rounded-lg p-4">
                  <h3 class="text-lg font-semibold text-traffic-green mb-3 font-workshop">
                    Strengths ({length(@strengths)})
                  </h3>
                  <ul class="space-y-2">
                    <%= for item <- @strengths do %>
                      <li class="flex items-center gap-2 text-ink-blue/70">
                        <span class="text-traffic-green">✓</span>
                        <span class="font-workshop">{item.title}</span>
                        <span class="text-traffic-green font-semibold ml-auto font-workshop">
                          {round(item.combined_team_value)}/10
                        </span>
                      </li>
                    <% end %>
                  </ul>
                </div>
              <% end %>
              
    <!-- Concerns -->
              <%= if length(@concerns) > 0 do %>
                <div class="bg-red-50 border border-traffic-red rounded-lg p-4">
                  <h3 class="text-lg font-semibold text-traffic-red mb-3 font-workshop">
                    Areas of Concern ({length(@concerns)})
                  </h3>
                  <ul class="space-y-2">
                    <%= for item <- @concerns do %>
                      <li class="flex items-center gap-2 text-ink-blue/70">
                        <span class="text-traffic-red">!</span>
                        <span class="font-workshop">{item.title}</span>
                        <span class="text-traffic-red font-semibold ml-auto font-workshop">
                          {round(item.combined_team_value)}/10
                        </span>
                      </li>
                    <% end %>
                  </ul>
                </div>
              <% end %>
            </div>
          <% end %>
          
    <!-- Action Items Section -->
          <div class="bg-surface-wall/50 rounded-lg p-4 mb-6">
            <h2 class="text-sm font-semibold text-ink-blue/60 mb-3 font-brand uppercase tracking-wide">
              Action Items
            </h2>
            
    <!-- Add Action Form -->
            <.live_component
              module={ActionFormComponent}
              id="action-form"
              session={@session}
            />
            
    <!-- Existing Actions -->
            <%= if @action_count > 0 do %>
              <ul class="space-y-2">
                <%= for action <- @all_actions do %>
                  {render_action_item(assigns, action)}
                <% end %>
              </ul>
            <% else %>
              <p class="text-ink-blue/60 text-center py-2 font-workshop">
                No action items yet. Add your first action above.
              </p>
            <% end %>
          </div>
          
    <!-- Export Modal -->
          <ExportModalComponent.render
            show_export_modal={@show_export_modal}
            export_content={@export_content}
            action_count={@action_count}
          />
          
    <!-- Navigation Footer -->
          <div class="pt-4 border-t border-ink-blue/10">
            <%= if @participant.is_facilitator do %>
              <div class="flex gap-3">
                <button
                  phx-click="go_back"
                  class="btn-workshop btn-workshop-secondary"
                >
                  ← Back
                </button>
                <button
                  phx-click="finish_workshop"
                  class="flex-1 btn-workshop btn-workshop-primary"
                >
                  Finish Workshop
                </button>
              </div>
              <p class="text-center text-ink-blue/50 text-sm mt-2 font-brand">
                Finish the workshop and return to the home page.
              </p>
            <% else %>
              <p class="text-center text-ink-blue/60 font-brand">
                Waiting for facilitator to finish the workshop...
              </p>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_action_item(assigns, action) do
    assigns = Map.put(assigns, :action, action)

    ~H"""
    <li class="rounded-lg p-3 flex items-start gap-3 bg-surface-sheet border border-ink-blue/5">
      <div class="flex-1">
        <p class="text-ink-blue font-workshop">{@action.description}</p>
        <%= if @action.owner_name && @action.owner_name != "" do %>
          <p class="text-sm text-ink-blue/50 mt-1 font-brand">
            Owner: {@action.owner_name}
          </p>
        <% end %>
      </div>
      <button
        type="button"
        phx-click="delete_action"
        phx-value-id={@action.id}
        class="text-ink-blue/40 hover:text-traffic-red transition-colors text-sm"
        title="Delete action"
      >
        ✕
      </button>
    </li>
    """
  end
end
