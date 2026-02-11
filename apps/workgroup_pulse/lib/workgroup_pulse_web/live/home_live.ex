defmodule WorkgroupPulseWeb.HomeLive do
  @moduledoc """
  Home page LiveView - entry point for creating workshop sessions.
  """
  use WorkgroupPulseWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Welcome")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-surface-wall flex flex-col items-center justify-center px-4">
      <.sheet class="shadow-sheet p-sheet-padding w-[520px]">
        <div class="text-center mb-6">
          <h1 class="font-workshop text-4xl font-bold text-ink-blue mb-1">
            Workgroup Pulse
          </h1>
          <p class="text-ink-blue/60 text-sm font-brand">
            Six Criteria for Productive Work
          </p>
        </div>

        <div class="mb-5">
          <div class="flex items-center gap-2 mb-2">
            <div class="w-6 h-6 rounded-md bg-accent-gold/10 flex items-center justify-center">
              <svg
                class="w-3.5 h-3.5 text-accent-gold"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 4v16m8-8H4"
                />
              </svg>
            </div>
            <h2 class="text-sm font-semibold text-ink-blue font-brand">New Workshop</h2>
          </div>
          <p class="text-ink-blue/60 text-xs font-brand mb-3">
            Create a session and lead your team through the Six Criteria.
          </p>
          <.link
            navigate={~p"/session/new"}
            class="block w-full btn-workshop btn-workshop-primary text-center py-2.5"
          >
            Start New Workshop
          </.link>
        </div>

        <p class="text-ink-blue/40 text-xs text-center mt-5 font-brand">
          No account required. Sessions are temporary.
        </p>
      </.sheet>
    </div>
    """
  end
end
