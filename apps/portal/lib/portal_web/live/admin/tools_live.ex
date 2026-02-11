defmodule PortalWeb.Admin.ToolsLive do
  @moduledoc """
  Admin page for managing tool status and kill switches.
  """
  use PortalWeb, :live_view

  alias Portal.Tools
  alias Portal.Tools.Tool

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Tool Management", tools: Tools.list_tools())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl py-8">
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-text-dark">Tool Management</h1>
        <p class="mt-1 text-sm text-zinc-600">
          Control tool visibility and status on the dashboard
        </p>
      </div>

      <div class="overflow-hidden rounded-lg border border-zinc-200 bg-surface-sheet shadow-sheet">
        <table class="min-w-full divide-y divide-zinc-200">
          <thead class="bg-surface-sheet-secondary">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Tool
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Default Status
              </th>
              <th class="px-6 py-3 text-center text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Admin Enabled
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Effective Status
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                URL
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-200">
            <tr :for={tool <- @tools} class="hover:bg-surface-sheet-secondary">
              <td class="px-6 py-4">
                <div class="text-sm font-medium text-text-dark">{tool.name}</div>
                <div class="text-xs text-zinc-500">{tool.tagline}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class={[
                  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
                  tool.default_status == "live" && "bg-ok-green-100 text-ok-green-800",
                  tool.default_status == "coming_soon" && "bg-zinc-100 text-zinc-700"
                ]}>
                  {format_default_status(tool.default_status)}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-center">
                <button
                  phx-click="toggle_enabled"
                  phx-value-id={tool.id}
                  class={[
                    "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-ok-purple-500 focus:ring-offset-2",
                    tool.admin_enabled && "bg-ok-green-500",
                    !tool.admin_enabled && "bg-zinc-300"
                  ]}
                  role="switch"
                  aria-checked={to_string(tool.admin_enabled)}
                >
                  <span class={[
                    "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
                    tool.admin_enabled && "translate-x-5",
                    !tool.admin_enabled && "translate-x-0"
                  ]}>
                  </span>
                </button>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class={[
                  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
                  Tool.effective_status(tool) == :live && "bg-ok-green-100 text-ok-green-800",
                  Tool.effective_status(tool) == :coming_soon && "bg-zinc-100 text-zinc-700",
                  Tool.effective_status(tool) == :maintenance && "bg-ok-red-100 text-ok-red-800"
                ]}>
                  {format_effective_status(Tool.effective_status(tool))}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <a
                  :if={tool.url}
                  href={tool.url}
                  target="_blank"
                  class="text-ok-purple-600 hover:text-ok-purple-800"
                >
                  {tool.url}
                </a>
                <span :if={!tool.url} class="text-zinc-400">-</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("toggle_enabled", %{"id" => id}, socket) do
    tool = Tools.get_tool!(id)

    case Tools.toggle_admin_enabled(tool) do
      {:ok, _tool} ->
        action = if tool.admin_enabled, do: "disabled", else: "enabled"

        {:noreply,
         socket
         |> put_flash(:info, "#{tool.name} #{action}.")
         |> assign(:tools, Tools.list_tools())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update tool.")}
    end
  end

  defp format_default_status("live"), do: "Live"
  defp format_default_status("coming_soon"), do: "Coming Soon"
  defp format_default_status(status), do: status

  defp format_effective_status(:live), do: "Live"
  defp format_effective_status(:coming_soon), do: "Coming Soon"
  defp format_effective_status(:maintenance), do: "Maintenance"
end
