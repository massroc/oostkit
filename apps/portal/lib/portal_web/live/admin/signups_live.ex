defmodule PortalWeb.Admin.SignupsLive do
  @moduledoc """
  Admin page for managing email interest signups.
  """
  use PortalWeb, :live_view

  alias Portal.Marketing

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Email Signups",
       signups: Marketing.list_interest_signups(),
       search: ""
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-6 py-8 sm:px-8">
      <div class="mb-8">
        <.header>
          Email Signups
          <:subtitle>{length(@signups)} signups captured</:subtitle>
          <:actions>
            <a
              href={~p"/admin/signups/export"}
              class="rounded-lg bg-ok-purple-600 px-4 py-2 text-sm font-semibold text-white hover:bg-ok-purple-700"
            >
              Export CSV
            </a>
          </:actions>
        </.header>
      </div>

      <div class="mb-6">
        <form phx-change="search" phx-submit="search">
          <input
            type="text"
            name="query"
            value={@search}
            placeholder="Search by name, email, or context..."
            class="w-full rounded-lg border border-zinc-300 px-4 py-2 text-sm focus:border-ok-purple-400 focus:ring-ok-purple-400"
            phx-debounce="300"
          />
        </form>
      </div>

      <div class="overflow-hidden rounded-xl border border-zinc-200 bg-surface-sheet shadow-sheet">
        <table class="min-w-full divide-y divide-zinc-200">
          <thead class="bg-surface-sheet-secondary">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Name
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Email
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Context
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Date
              </th>
              <th class="px-6 py-3 text-right text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-200">
            <tr :if={@signups == []}>
              <td colspan="5" class="px-6 py-8 text-center text-sm text-zinc-500">
                No signups yet.
              </td>
            </tr>
            <tr :for={signup <- @signups} class="hover:bg-surface-sheet-secondary">
              <td class="px-6 py-4 whitespace-nowrap text-sm text-text-dark">
                {signup.name || "-"}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-text-dark">
                {signup.email}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="inline-flex items-center rounded-full bg-zinc-100 px-2.5 py-0.5 text-xs font-medium text-zinc-700">
                  {signup.context || "-"}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-600">
                {Calendar.strftime(signup.inserted_at, "%d %b %Y %H:%M")}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <button
                  phx-click="delete_signup"
                  phx-value-id={signup.id}
                  data-confirm="Are you sure you want to delete this signup?"
                  class="text-ok-red-600 hover:text-ok-red-800"
                >
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, signups: reload_signups(query), search: query)}
  end

  def handle_event("delete_signup", %{"id" => id}, socket) do
    signup = Marketing.get_interest_signup!(id)
    {:ok, _} = Marketing.delete_interest_signup(signup)

    signups = reload_signups(socket.assigns.search)

    {:noreply,
     socket
     |> put_flash(:info, "Signup deleted.")
     |> assign(:signups, signups)}
  end

  defp reload_signups(search) do
    if String.trim(search) == "" do
      Marketing.list_interest_signups()
    else
      Marketing.search_interest_signups(search)
    end
  end
end
