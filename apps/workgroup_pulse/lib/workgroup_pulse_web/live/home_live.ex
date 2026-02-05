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
      <div class="max-w-2xl w-full text-center">
        <h1 class="text-4xl font-bold text-text-dark mb-4 font-brand">
          Productive Work Groups
        </h1>
        <p class="text-xl text-text-body mb-12">
          A self-guided workshop for exploring the Six Criteria of Productive Work
        </p>

        <div class="grid md:grid-cols-2 gap-section-gap max-w-xl mx-auto items-stretch">
          <!-- Facilitate Option -->
          <div class="bg-surface-sheet rounded-sheet shadow-sheet p-sheet-padding text-left flex flex-col">
            <h2 class="text-xl font-semibold text-text-dark mb-2">Facilitate</h2>
            <p class="text-text-body text-sm mb-4">
              Create a new workshop session and lead your team through the Six Criteria.
            </p>
            <.link
              navigate={~p"/session/new"}
              class="block w-full px-4 py-3 bg-accent-purple hover:bg-highlight text-white font-semibold rounded-lg transition-colors text-center mt-auto"
            >
              Start New Workshop
            </.link>
          </div>

          <!-- Join Option -->
          <div class="bg-surface-sheet rounded-sheet shadow-sheet p-sheet-padding text-left flex flex-col">
            <h2 class="text-xl font-semibold text-text-dark mb-2">Join</h2>
            <p class="text-text-body text-sm mb-4">
              Enter a session code to join an existing workshop as a participant.
            </p>
            <form phx-submit="join_session" class="space-y-3 mt-auto">
              <input
                type="text"
                name="code"
                value={@join_code}
                phx-change="update_code"
                placeholder="Enter code (e.g. ABC123)"
                class="w-full bg-surface-wall border border-gray-300 rounded-lg px-4 py-3 text-text-dark placeholder-text-body focus:ring-2 focus:ring-accent-purple focus:border-transparent font-mono uppercase"
                maxlength="6"
              />
              <%= if @join_error do %>
                <p class="text-accent-red text-sm">{@join_error}</p>
              <% end %>
              <button
                type="submit"
                class="w-full px-4 py-3 bg-df-green hover:bg-secondary-green-light text-white font-semibold rounded-lg transition-colors"
              >
                Join Workshop
              </button>
            </form>
          </div>
        </div>

        <p class="text-text-body text-sm mt-8">
          No account required. Sessions are temporary and data is not stored permanently.
        </p>
      </div>
    </div>
    """
  end
end
