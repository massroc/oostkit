defmodule PortalWeb.Admin.StatusLive do
  @moduledoc """
  Admin status page showing app health and recent CI results.
  """
  use PortalWeb, :live_view

  alias Portal.StatusPoller

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      StatusPoller.subscribe()
    end

    status = StatusPoller.get_status()

    {:ok,
     assign(socket,
       page_title: "System Status",
       health: status.health,
       ci: status.ci,
       last_polled: status.last_polled
     )}
  end

  @impl true
  def handle_info({:status_update, status}, socket) do
    {:noreply,
     assign(socket,
       health: status.health,
       ci: status.ci,
       last_polled: status.last_polled
     )}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    StatusPoller.refresh()
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-6 py-8 sm:px-8">
      <div class="mb-8 flex items-center justify-between">
        <.header>
          System Status
          <:subtitle>App health and CI pipeline status</:subtitle>
        </.header>
        <button
          phx-click="refresh"
          class="rounded-lg border border-zinc-200 px-3 py-1.5 text-sm text-zinc-600 hover:bg-zinc-50"
        >
          Refresh now
        </button>
      </div>

      <div class="rounded-xl border border-zinc-200 bg-surface-sheet p-6 shadow-sheet mb-8">
        <h2 class="text-lg font-semibold text-text-dark mb-4">App Health</h2>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <.health_card :for={{name, data} <- @health} name={name} data={data} />
          <div
            :if={@health == %{}}
            class="col-span-3 text-center text-sm text-zinc-400 py-4"
          >
            Waiting for first health check...
          </div>
        </div>
      </div>

      <div class="rounded-xl border border-zinc-200 bg-surface-sheet p-6 shadow-sheet mb-8">
        <h2 class="text-lg font-semibold text-text-dark mb-4">CI Status</h2>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <.ci_card :for={{name, runs} <- @ci} name={name} runs={runs} />
          <div
            :if={@ci == %{}}
            class="col-span-3 text-center text-sm text-zinc-400 py-4"
          >
            Waiting for first CI status check...
          </div>
        </div>
      </div>

      <p class="text-center text-xs text-zinc-400">
        Auto-refreshes every 5 minutes.
        <%= if @last_polled do %>
          Last polled: {format_time(@last_polled)}
        <% end %>
      </p>
    </div>
    """
  end

  defp health_card(assigns) do
    ~H"""
    <div class="rounded-lg border border-zinc-200 p-4">
      <div class="flex items-center gap-2 mb-2">
        <span class={["inline-block h-2.5 w-2.5 rounded-full", health_dot_class(@data)]} />
        <span class="font-medium text-text-dark">{@name}</span>
      </div>
      <div class="text-xs text-zinc-500 space-y-1">
        <%= if @data[:healthy] do %>
          <div>Response: {@data.response_time_ms}ms</div>
        <% else %>
          <div class="text-ok-red-600">{@data[:error] || "HTTP #{@data[:status]}"}</div>
        <% end %>
        <div>Last checked: {format_time(@data[:checked_at])}</div>
      </div>
    </div>
    """
  end

  defp ci_card(assigns) do
    latest = List.first(assigns.runs)
    assigns = assign(assigns, :latest, latest)

    ~H"""
    <div class="rounded-lg border border-zinc-200 p-4">
      <div class="flex items-center gap-2 mb-2">
        <span class={["inline-block h-2.5 w-2.5 rounded-full", ci_dot_class(@latest)]} />
        <span class="font-medium text-text-dark">{@name}</span>
      </div>
      <div class="text-xs text-zinc-500 space-y-1">
        <%= if @latest do %>
          <div>
            {ci_label(@latest)} · {String.slice(@latest.head_sha, 0..6)}
          </div>
          <div>{format_time_string(@latest.created_at)}</div>
          <.link
            href={@latest.html_url}
            target="_blank"
            class="text-ok-purple-600 hover:text-ok-purple-800"
          >
            View run
          </.link>
        <% else %>
          <div class="text-zinc-400">No recent runs</div>
        <% end %>
      </div>
    </div>
    """
  end

  defp health_dot_class(%{healthy: true}), do: "bg-ok-green-500"
  defp health_dot_class(_), do: "bg-ok-red-500"

  defp ci_dot_class(%{conclusion: "success"}), do: "bg-ok-green-500"
  defp ci_dot_class(%{conclusion: "failure"}), do: "bg-ok-red-500"
  defp ci_dot_class(%{status: "in_progress"}), do: "bg-ok-gold-500"
  defp ci_dot_class(_), do: "bg-zinc-300"

  defp ci_label(%{conclusion: "success"}), do: "Passed"
  defp ci_label(%{conclusion: "failure"}), do: "Failed"
  defp ci_label(%{status: "in_progress"}), do: "Running"
  defp ci_label(%{conclusion: c}) when is_binary(c), do: String.capitalize(c)
  defp ci_label(_), do: "Unknown"

  defp format_time(nil), do: "never"

  defp format_time(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M UTC")
  end

  defp format_time_string(nil), do: "unknown"

  defp format_time_string(str) when is_binary(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> format_time(dt)
      _ -> str
    end
  end
end
