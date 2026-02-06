defmodule WorkgroupPulseWeb.SessionLive.Components.ActionsComponent do
  @moduledoc """
  Renders the actions phase of a workshop session.
  Displays action items and form for creating new ones.
  Uses Virtual Wall design with paper-textured sheet.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  alias WorkgroupPulseWeb.SessionLive.ActionFormComponent

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :all_actions, :list, required: true
  attr :action_count, :integer, required: true

  def render(assigns) do
    ~H"""
    <div class="flex items-start justify-center h-full p-6 overflow-auto">
      <!-- Main Sheet -->
      <div
        class="paper-texture rounded-sheet shadow-sheet p-6 max-w-3xl w-full"
        style="transform: rotate(-0.2deg)"
      >
        <div class="relative z-[1]">
          <!-- Header -->
          <div class="text-center mb-6 pb-4 border-b-2 border-ink-blue/10">
            <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-2">
              Action Items
            </h1>
            <p class="text-ink-blue/70">
              Capture commitments and next steps from your discussion.
            </p>
          </div>
          
    <!-- Create Action Form -->
          <.live_component
            module={ActionFormComponent}
            id="action-form"
            session={@session}
          />
          
    <!-- Existing Actions -->
          <%= if @action_count > 0 do %>
            <div class="bg-surface-wall/50 rounded-lg p-4 mb-6">
              <ul class="space-y-3">
                <%= for action <- @all_actions do %>
                  {render_action_item(assigns, action)}
                <% end %>
              </ul>
            </div>
          <% else %>
            <div class="bg-surface-wall/50 rounded-lg p-6 text-center mb-6">
              <p class="text-ink-blue/60 font-workshop">
                No action items yet. Add your first action above.
              </p>
            </div>
          <% end %>
          
    <!-- Finish Workshop Button -->
          <div class="pt-4 border-t border-ink-blue/10">
            <%= if @participant.is_facilitator do %>
              <button
                phx-click="finish_workshop"
                class="w-full btn-workshop btn-workshop-primary py-3"
              >
                Finish Workshop
              </button>
              <p class="text-center text-ink-blue/50 text-sm mt-2 font-brand">
                Complete the workshop and view the final summary.
              </p>
            <% else %>
              <div class="text-center text-ink-blue/60 font-brand">
                Adding action items. Waiting for facilitator to finish workshop...
              </div>
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
        class="text-ink-blue/40 hover:text-accent-red transition-colors text-sm"
        title="Delete action"
      >
        ✕
      </button>
    </li>
    """
  end
end
