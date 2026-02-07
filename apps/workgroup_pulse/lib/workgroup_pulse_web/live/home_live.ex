defmodule WorkgroupPulseWeb.HomeLive do
  @moduledoc """
  Home page LiveView - entry point for creating or joining workshop sessions.
  """
  use WorkgroupPulseWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Welcome")
     |> assign(join_code: "")
     |> assign(join_error: nil)}
  end

  @impl true
  def handle_event("update_code", %{"code" => code}, socket) do
    {:noreply, assign(socket, join_code: String.upcase(code), join_error: nil)}
  end

  @impl true
  def handle_event("join_session", %{"code" => code}, socket) do
    code = String.trim(code) |> String.upcase()

    if code == "" do
      {:noreply, assign(socket, join_error: "Please enter a session code")}
    else
      case WorkgroupPulse.Sessions.get_session_by_code(code) do
        nil ->
          {:noreply,
           assign(socket, join_error: "Session not found. Check the code and try again.")}

        _session ->
          {:noreply, push_navigate(socket, to: ~p"/session/#{code}/join")}
      end
    end
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

        <%!-- Facilitate --%>
        <div class="mb-5">
          <div class="flex items-center gap-2 mb-2">
            <div class="w-6 h-6 rounded-md bg-accent-purple/10 flex items-center justify-center">
              <svg
                class="w-3.5 h-3.5 text-accent-purple"
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

        <%!-- Divider --%>
        <div class="flex items-center gap-3 mb-5">
          <div class="flex-1 border-t border-ink-blue/10"></div>
          <span class="text-xs text-ink-blue/40 font-brand">or</span>
          <div class="flex-1 border-t border-ink-blue/10"></div>
        </div>

        <%!-- Join --%>
        <div>
          <div class="flex items-center gap-2 mb-2">
            <div class="w-6 h-6 rounded-md bg-df-green/10 flex items-center justify-center">
              <svg
                class="w-3.5 h-3.5 text-df-green"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"
                />
              </svg>
            </div>
            <h2 class="text-sm font-semibold text-ink-blue font-brand">Join Workshop</h2>
          </div>
          <p class="text-ink-blue/60 text-xs font-brand mb-3">
            Enter a session code to join as a participant.
          </p>
          <form phx-submit="join_session" class="space-y-2">
            <input
              type="text"
              name="code"
              value={@join_code}
              phx-change="update_code"
              placeholder="e.g. ABC123"
              class="w-full bg-surface-wall border border-ink-blue/10 rounded-lg px-4 py-2.5 text-ink-blue placeholder-ink-blue/30 focus:ring-2 focus:ring-accent-purple focus:border-transparent font-mono text-lg uppercase tracking-widest text-center"
              maxlength="6"
            />
            <p :if={@join_error} class="text-accent-red text-xs font-brand">{@join_error}</p>
            <button
              type="submit"
              class="w-full btn-workshop btn-workshop-secondary py-2.5 border-2 border-df-green text-df-green hover:bg-df-green hover:text-white"
            >
              Join Workshop
            </button>
          </form>
        </div>

        <p class="text-ink-blue/40 text-xs text-center mt-5 font-brand">
          No account required. Sessions are temporary.
        </p>
      </.sheet>
    </div>
    """
  end
end
