defmodule WorkgroupPulseWeb.SessionLive.Components.CompletedComponent do
  @moduledoc """
  Renders the wrap-up/completed phase of a workshop session.
  Shows final scores, strengths, concerns, action items, and export options.
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
    <div class="flex flex-col items-center min-h-screen px-4 py-8">
      <div class="max-w-4xl w-full">
        <!-- Header -->
        <div class="text-center mb-8">
          <h1 class="text-3xl font-bold text-text-dark mb-2">Workshop Wrap-Up</h1>

          <p class="text-text-body">Review key findings and create action items.</p>

          <p class="text-sm text-gray-500 mt-2">
            Session code: <span class="font-mono text-text-dark">{@session.code}</span>
          </p>
        </div>
        <!-- Score Grid -->
        <div class="bg-surface-sheet rounded-lg p-4 mb-6">
          <h2 class="text-lg font-semibold text-text-dark mb-3">All Scores</h2>

          <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <%= for score <- @scores_summary do %>
              <div class={["rounded-lg p-3 text-center border", card_color_class(score.color)]}>
                <div class="text-xs text-text-body mb-1">Q{score.question_index + 1}</div>

                <div class={["text-2xl font-bold", text_color_class(score.color)]}>
                  <%= if score.combined_team_value do %>
                    {round(score.combined_team_value)}/10
                  <% else %>
                    —
                  <% end %>
                </div>

                <div class="text-xs text-text-body truncate mt-1" title={score.title}>
                  {score.title}
                </div>
              </div>
            <% end %>
          </div>

          <div class="flex items-center justify-center gap-1 text-xs text-gray-500 mt-2">
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
                <h3 class="text-lg font-semibold text-traffic-green mb-3">
                  Strengths ({length(@strengths)})
                </h3>

                <ul class="space-y-2">
                  <%= for item <- @strengths do %>
                    <li class="flex items-center gap-2 text-text-body">
                      <span class="text-traffic-green">✓</span> <span>{item.title}</span>
                      <span class="text-traffic-green font-semibold ml-auto">
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
                <h3 class="text-lg font-semibold text-traffic-red mb-3">
                  Areas of Concern ({length(@concerns)})
                </h3>

                <ul class="space-y-2">
                  <%= for item <- @concerns do %>
                    <li class="flex items-center gap-2 text-text-body">
                      <span class="text-traffic-red">!</span> <span>{item.title}</span>
                      <span class="text-traffic-red font-semibold ml-auto">
                        {round(item.combined_team_value)}/10
                      </span>
                    </li>
                  <% end %>
                </ul>
              </div>
            <% end %>
          </div>
        <% end %>
        <!-- Action Items Section (Editable) -->
        <div class="bg-surface-sheet rounded-lg p-4 mb-6">
          <h2 class="text-lg font-semibold text-text-dark mb-3">Action Items</h2>
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
            <p class="text-text-body text-center py-2">
              No action items yet. Add your first action above.
            </p>
          <% end %>
        </div>
        <!-- Export -->
        <ExportModalComponent.render
          show_export_modal={@show_export_modal}
          export_content={@export_content}
          action_count={@action_count}
        />
        <!-- Navigation Footer -->
        <div class="bg-surface-sheet rounded-lg p-6">
          <%= if @participant.is_facilitator do %>
            <div class="flex gap-3">
              <button
                phx-click="go_back"
                class="px-6 py-3 bg-gray-100 hover:bg-gray-600 text-text-body hover:text-text-dark font-medium rounded-lg transition-colors flex items-center gap-2"
              >
                <span>←</span> <span>Back</span>
              </button>
              <button
                phx-click="finish_workshop"
                class="flex-1 px-6 py-3 bg-accent-purple hover:bg-highlight text-white font-semibold rounded-lg transition-colors"
              >
                Finish Workshop
              </button>
            </div>

            <p class="text-center text-gray-500 text-sm mt-2">
              Finish the workshop and return to the home page.
            </p>
          <% else %>
            <p class="text-center text-text-body">Waiting for facilitator to finish the workshop...</p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp render_action_item(assigns, action) do
    assigns = Map.put(assigns, :action, action)

    ~H"""
    <li class="rounded-lg p-3 flex items-start gap-3 bg-gray-100">
      <div class="flex-1">
        <p class="text-text-body">{@action.description}</p>

        <%= if @action.owner_name && @action.owner_name != "" do %>
          <p class="text-sm text-gray-500 mt-1">Owner: {@action.owner_name}</p>
        <% end %>
      </div>

      <button
        type="button"
        phx-click="delete_action"
        phx-value-id={@action.id}
        class="text-gray-500 hover:text-traffic-red transition-colors text-sm"
        title="Delete action"
      >
        ✕
      </button>
    </li>
    """
  end
end
