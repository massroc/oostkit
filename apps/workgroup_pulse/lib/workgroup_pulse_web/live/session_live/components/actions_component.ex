defmodule WorkgroupPulseWeb.SessionLive.Components.ActionsComponent do
  @moduledoc """
  Renders the actions phase of a workshop session.
  Displays action items and form for creating new ones.
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
    <div class="flex flex-col items-center min-h-screen px-4 py-8">
      <div class="max-w-3xl w-full">
        <div class="text-center mb-8">
          <h1 class="text-3xl font-bold text-text-dark mb-2">Action Items</h1>

          <p class="text-text-body">Capture commitments and next steps from your discussion.</p>
        </div>
        <!-- Create Action Form -->
        <.live_component
          module={ActionFormComponent}
          id="action-form"
          session={@session}
        />
        <!-- Existing Actions -->
        <%= if @action_count > 0 do %>
          <div class="bg-surface-sheet rounded-lg p-6">
            <ul class="space-y-3">
              <%= for action <- @all_actions do %>
                {render_action_item(assigns, action)}
              <% end %>
            </ul>
          </div>
        <% else %>
          <div class="bg-surface-sheet rounded-lg p-6 text-center">
            <p class="text-text-body">No action items yet. Add your first action above.</p>
          </div>
        <% end %>
        <!-- Finish Workshop Button -->
        <div class="bg-surface-sheet rounded-lg p-6 mt-6">
          <%= if @participant.is_facilitator do %>
            <button
              phx-click="finish_workshop"
              class="w-full px-6 py-3 bg-accent-purple hover:bg-highlight text-white font-semibold rounded-lg transition-colors"
            >
              Finish Workshop
            </button>
            <p class="text-center text-gray-500 text-sm mt-2">
              Complete the workshop and view the final summary.
            </p>
          <% else %>
            <div class="text-center text-text-body">
              Adding action items. Waiting for facilitator to finish workshop...
            </div>
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
        class="text-gray-500 hover:text-red-400 transition-colors text-sm"
        title="Delete action"
      >
        ✕
      </button>
    </li>
    """
  end
end
