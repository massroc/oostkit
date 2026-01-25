defmodule ProductiveWorkgroupsWeb.SessionLive.New do
  @moduledoc """
  LiveView for creating a new workshop session as a facilitator.
  """
  use ProductiveWorkgroupsWeb, :live_view

  alias ProductiveWorkgroups.Workshops

  @impl true
  def mount(_params, _session, socket) do
    template = Workshops.get_template_by_slug("six-criteria")

    {:ok,
     socket
     |> assign(page_title: "Create Workshop")
     |> assign(template: template)
     |> assign(facilitator_name: "")
     |> assign(duration: "210")
     |> assign(error: nil)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    name = params["facilitator_name"] || ""
    duration = params["duration"] || "210"

    {:noreply,
     socket
     |> assign(facilitator_name: name)
     |> assign(duration: duration)
     |> assign(error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 flex flex-col items-center justify-center px-4">
      <div class="max-w-md w-full">
        <.link navigate={~p"/"} class="text-gray-400 hover:text-white mb-8 inline-flex items-center">
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M10 19l-7-7m0 0l7-7m-7 7h18"
            />
          </svg>
          Back to Home
        </.link>

        <h1 class="text-2xl font-bold text-white mb-2 text-center">
          Create New Workshop
        </h1>
        <p class="text-gray-400 text-center mb-8">
          Set up your Six Criteria workshop and invite your team
        </p>

        <form action={~p"/session/create"} method="post" phx-change="validate" class="space-y-6">
          <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />

          <div>
            <label for="facilitator_name" class="block text-sm font-medium text-gray-300 mb-2">
              Your Name (Facilitator)
            </label>
            <input
              type="text"
              name="facilitator_name"
              id="facilitator_name"
              value={@facilitator_name}
              placeholder="Enter your name"
              class="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white placeholder-gray-500 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              autofocus
              required
            />
          </div>

          <div>
            <label for="duration" class="block text-sm font-medium text-gray-300 mb-2">
              Planned Duration
            </label>
            <select
              name="duration"
              id="duration"
              class="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="60" selected={@duration == "60"}>1 hour (Quick session)</option>
              <option value="120" selected={@duration == "120"}>2 hours (Focused session)</option>
              <option value="210" selected={@duration == "210"}>3.5 hours (Recommended)</option>
              <option value="240" selected={@duration == "240"}>4 hours (Half day)</option>
              <option value="360" selected={@duration == "360"}>6 hours (Full day)</option>
            </select>
            <p class="mt-2 text-sm text-gray-500">
              Choose based on your team's experience. First-time teams should allow more time.
            </p>
          </div>

          <%= if @error do %>
            <p class="text-red-400 text-sm">{@error}</p>
          <% end %>

          <button
            type="submit"
            class="w-full px-6 py-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors text-lg"
          >
            Create Workshop
          </button>
        </form>

        <p class="text-gray-500 text-sm text-center mt-6">
          You'll get a code to share with your team so they can join.
        </p>
      </div>
    </div>
    """
  end
end
