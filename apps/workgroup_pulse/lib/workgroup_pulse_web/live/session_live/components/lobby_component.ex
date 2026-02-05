defmodule WorkgroupPulseWeb.SessionLive.Components.LobbyComponent do
  @moduledoc """
  Renders the lobby/waiting room phase of a workshop session.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :participants, :list, required: true

  def render(assigns) do
    join_url = WorkgroupPulseWeb.Endpoint.url() <> "/session/#{assigns.session.code}/join"
    assigns = assign(assigns, :join_url, join_url)

    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen px-4">
      <div class="max-w-lg w-full text-center">
        <h1 class="text-3xl font-bold text-text-dark mb-2 font-brand">Waiting Room</h1>

        <p class="text-text-body mb-4">Share this link with your team:</p>

        <div class="bg-surface-sheet rounded-sheet shadow-sheet p-4 mb-8">
          <div class="flex items-center gap-2">
            <input
              type="text"
              readonly
              value={@join_url}
              id="join-url"
              class="flex-1 bg-surface-wall border-none rounded-lg px-4 py-3 text-text-dark font-mono text-sm focus:ring-2 focus:ring-accent-purple"
            />
            <button
              type="button"
              phx-click={JS.dispatch("phx:copy", to: "#join-url")}
              class="px-4 py-3 bg-accent-purple hover:bg-highlight text-white font-medium rounded-lg transition-colors"
            >
              Copy
            </button>
          </div>
        </div>

        <div class="bg-surface-sheet rounded-sheet shadow-sheet p-6 mb-6">
          <h2 class="text-lg font-semibold text-text-dark mb-4">
            Participants ({length(@participants)})
          </h2>

          <ul class="space-y-2">
            <%= for p <- @participants do %>
              <li class="flex items-center justify-between bg-surface-wall rounded-lg px-4 py-3">
                <div class="flex items-center gap-2">
                  <span class="text-text-dark">{p.name}</span>
                  <%= cond do %>
                    <% p.is_observer -> %>
                      <span class="text-xs bg-gray-200 text-text-body px-2 py-1 rounded">
                        Observer
                      </span>
                    <% p.is_facilitator -> %>
                      <span class="text-xs bg-accent-purple text-white px-2 py-1 rounded">
                        Facilitator
                      </span>
                    <% true -> %>
                  <% end %>
                </div>

                <%= if p.id == @participant.id do %>
                  <span class="text-xs bg-accent-purple text-white px-2 py-1 rounded">You</span>
                <% end %>
              </li>
            <% end %>
          </ul>
        </div>

        <%= if @participant.is_facilitator do %>
          <button
            phx-click="start_workshop"
            class="w-full px-6 py-4 font-semibold rounded-lg transition-colors text-lg mb-4 bg-df-green hover:bg-secondary-green-light text-white"
          >
            Start Workshop
          </button>
          <p class="text-text-body text-sm">Click above when everyone has joined.</p>
        <% else %>
          <p class="text-text-body text-sm">Waiting for the facilitator to start the workshop...</p>
        <% end %>
      </div>
    </div>
    """
  end
end
