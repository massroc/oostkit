defmodule WorkgroupPulseWeb.SessionLive.Components.LobbyComponent do
  @moduledoc """
  Renders the lobby phase as a sheet in the carousel.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]

  alias Phoenix.LiveView.JS

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :participants, :list, required: true

  def render(assigns) do
    join_url = WorkgroupPulseWeb.Endpoint.url() <> "/session/#{assigns.session.code}/join"
    assigns = assign(assigns, :join_url, join_url)

    ~H"""
    <.sheet class="shadow-sheet p-6 w-[960px] h-full">
      <div class="text-center max-w-lg mx-auto">
        <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-2">
          Waiting Room
        </h1>

        <p class="text-ink-blue/70 mb-4">Share this link with your team:</p>

        <div class="bg-surface-wall rounded-lg p-3 mb-6">
          <div class="flex items-center gap-2">
            <input
              type="text"
              readonly
              value={@join_url}
              id="join-url"
              class="flex-1 bg-surface-sheet border border-ink-blue/10 rounded-lg px-4 py-2.5 text-ink-blue font-mono text-sm focus:ring-2 focus:ring-accent-purple focus:border-transparent"
            />
            <button
              type="button"
              phx-click={JS.dispatch("phx:copy", to: "#join-url")}
              class="btn-workshop btn-workshop-primary"
            >
              Copy
            </button>
          </div>
        </div>

        <div class="bg-surface-wall/50 rounded-lg p-4 mb-5">
          <h2 class="font-workshop text-lg font-semibold text-ink-blue mb-3">
            Participants ({length(@participants)})
          </h2>

          <ul class="space-y-2">
            <%= for p <- @participants do %>
              <li class="flex items-center justify-between bg-surface-sheet rounded-lg px-4 py-2.5 border border-ink-blue/5">
                <div class="flex items-center gap-2">
                  <span class="font-workshop text-ink-blue text-lg">{p.name}</span>
                  <%= if p.is_observer do %>
                    <span class="text-xs bg-surface-wall text-ink-blue/60 px-2 py-0.5 rounded font-brand">
                      Observer
                    </span>
                  <% end %>
                </div>

                <div class="flex items-center gap-2">
                  <%= if p.is_facilitator do %>
                    <span class="text-xs bg-accent-purple text-white px-2 py-0.5 rounded font-brand">
                      Facilitator
                    </span>
                  <% end %>
                  <%= if p.id == @participant.id do %>
                    <span class="text-xs bg-accent-magenta text-white px-2 py-0.5 rounded font-brand">
                      You
                    </span>
                  <% end %>
                </div>
              </li>
            <% end %>
          </ul>
        </div>

        <%= if @participant.is_facilitator do %>
          <button
            phx-click="start_workshop"
            class="w-full btn-workshop btn-workshop-primary text-lg py-3 mb-3"
          >
            Start Workshop
          </button>
          <p class="text-ink-blue/60 text-sm">
            Click above when everyone has joined.
          </p>
        <% else %>
          <p class="text-ink-blue/60 text-sm">
            Waiting for the facilitator to start the workshop...
          </p>
        <% end %>
      </div>
    </.sheet>
    """
  end
end
