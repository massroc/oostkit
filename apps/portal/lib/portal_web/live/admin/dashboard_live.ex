defmodule PortalWeb.Admin.DashboardLive do
  @moduledoc """
  Admin dashboard with platform stats and quick links.
  """
  use PortalWeb, :live_view

  alias Portal.Accounts
  alias Portal.Marketing
  alias Portal.Tools
  alias Portal.Tools.Tool

  @impl true
  def mount(_params, _session, socket) do
    tools = Tools.list_tools()

    {:ok,
     assign(socket,
       page_title: "Admin Dashboard",
       signup_count: Marketing.count_interest_signups(),
       user_count: Accounts.count_users(),
       active_user_count: Accounts.count_active_users(),
       tools: tools,
       live_count: count_by_status(tools, :live),
       coming_soon_count: count_by_status(tools, :coming_soon),
       maintenance_count: count_by_status(tools, :maintenance)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-6 py-8 sm:px-8">
      <div class="mb-8">
        <.header>
          Admin Dashboard
          <:subtitle>Platform overview and quick actions</:subtitle>
        </.header>
      </div>

      <div class="rounded-xl border border-zinc-200 bg-surface-sheet p-6 shadow-sheet mb-8">
        <h2 class="text-lg font-semibold text-text-dark mb-4">Quick Links</h2>
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <.link
            navigate={~p"/admin/users"}
            class="rounded-lg border border-zinc-200 p-4 text-center hover:bg-surface-sheet-secondary"
          >
            <div class="text-sm font-medium text-text-dark">Manage Users</div>
            <div class="text-xs text-zinc-500">Create and manage accounts</div>
          </.link>
          <.link
            navigate={~p"/admin/signups"}
            class="rounded-lg border border-zinc-200 p-4 text-center hover:bg-surface-sheet-secondary"
          >
            <div class="text-sm font-medium text-text-dark">Email Signups</div>
            <div class="text-xs text-zinc-500">View interest signups</div>
          </.link>
          <.link
            navigate={~p"/admin/tools"}
            class="rounded-lg border border-zinc-200 p-4 text-center hover:bg-surface-sheet-secondary"
          >
            <div class="text-sm font-medium text-text-dark">Tool Status</div>
            <div class="text-xs text-zinc-500">Enable/disable tools</div>
          </.link>
          <.link
            navigate={~p"/admin/status"}
            class="rounded-lg border border-zinc-200 p-4 text-center hover:bg-surface-sheet-secondary"
          >
            <div class="text-sm font-medium text-text-dark">System Status</div>
            <div class="text-xs text-zinc-500">Health & CI status</div>
          </.link>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 mb-8">
        <div class="rounded-xl border border-zinc-200 bg-surface-sheet p-6 shadow-sheet">
          <dt class="text-sm font-medium text-zinc-500">Email Signups</dt>
          <dd class="mt-2 flex items-baseline">
            <span class="text-3xl font-bold text-text-dark">{@signup_count}</span>
            <.link
              navigate={~p"/admin/signups"}
              class="ml-auto text-sm text-ok-purple-600 hover:text-ok-purple-800"
            >
              View →
            </.link>
          </dd>
        </div>

        <div class="rounded-xl border border-zinc-200 bg-surface-sheet p-6 shadow-sheet">
          <dt class="text-sm font-medium text-zinc-500">Registered Users</dt>
          <dd class="mt-2 flex items-baseline">
            <span class="text-3xl font-bold text-text-dark">{@user_count}</span>
            <.link
              navigate={~p"/admin/users"}
              class="ml-auto text-sm text-ok-purple-600 hover:text-ok-purple-800"
            >
              View →
            </.link>
          </dd>
        </div>

        <div class="rounded-xl border border-zinc-200 bg-surface-sheet p-6 shadow-sheet">
          <dt class="text-sm font-medium text-zinc-500">Active Users (30d)</dt>
          <dd class="mt-2">
            <span class="text-3xl font-bold text-text-dark">{@active_user_count}</span>
          </dd>
        </div>
      </div>

      <div class="rounded-xl border border-zinc-200 bg-surface-sheet p-6 shadow-sheet">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-semibold text-text-dark">Tool Status</h2>
          <.link
            navigate={~p"/admin/tools"}
            class="text-sm font-medium text-ok-purple-600 hover:text-ok-purple-800"
          >
            Manage tools →
          </.link>
        </div>
        <div class="grid grid-cols-3 gap-4 text-center">
          <div>
            <div class="text-2xl font-bold text-ok-green-600">{@live_count}</div>
            <div class="text-xs text-zinc-500 uppercase">Live</div>
          </div>
          <div>
            <div class="text-2xl font-bold text-zinc-400">{@coming_soon_count}</div>
            <div class="text-xs text-zinc-500 uppercase">Coming Soon</div>
          </div>
          <div>
            <div class="text-2xl font-bold text-ok-red-600">{@maintenance_count}</div>
            <div class="text-xs text-zinc-500 uppercase">Maintenance</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp count_by_status(tools, status) do
    Enum.count(tools, &(Tool.effective_status(&1) == status))
  end
end
