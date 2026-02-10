defmodule PortalWeb.Admin.UsersLive do
  @moduledoc """
  LiveView for admin user management.
  """
  use PortalWeb, :live_view

  alias Portal.Accounts

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_users()
    {:ok, assign(socket, users: users, show_form: false, editing_user: nil, form: nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "User Management")
    |> assign(:show_form, false)
    |> assign(:editing_user, nil)
    |> assign(:form, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create User")
    |> assign(:show_form, true)
    |> assign(:editing_user, nil)
    |> assign(:form, to_form(%{"email" => "", "name" => ""}, as: "user"))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = Accounts.get_user!(id)

    socket
    |> assign(:page_title, "Edit User")
    |> assign(:show_form, true)
    |> assign(:editing_user, user)
    |> assign(:form, to_form(%{"name" => user.name || "", "role" => user.role}, as: "user"))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl py-8">
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold text-text-dark">User Management</h1>
          <p class="mt-1 text-sm text-zinc-600">Manage session manager accounts</p>
        </div>
        <.link
          :if={!@show_form}
          patch={~p"/admin/users/new"}
          class="rounded-lg bg-ok-purple-600 px-4 py-2 text-sm font-semibold text-white hover:bg-ok-purple-700"
        >
          Create User
        </.link>
      </div>

      <div
        :if={@show_form}
        class="mb-8 rounded-lg border border-zinc-200 bg-surface-sheet p-6 shadow-sheet"
      >
        <h2 class="text-lg font-semibold mb-4">
          {if @editing_user, do: "Edit User", else: "Create New User"}
        </h2>

        <.form for={@form} phx-submit="save_user" class="space-y-4">
          <div>
            <.field
              field={@form[:email]}
              type="email"
              label="Email"
              required={!@editing_user}
              readonly={!!@editing_user}
            />
          </div>
          <div>
            <.field field={@form[:name]} type="text" label="Name (optional)" />
          </div>
          <div :if={@editing_user}>
            <.field
              field={@form[:role]}
              type="select"
              label="Role"
              options={[{"Session Manager", "session_manager"}, {"Super Admin", "super_admin"}]}
            />
          </div>
          <div class="flex gap-4">
            <.button type="submit">
              {if @editing_user, do: "Update User", else: "Create User"}
            </.button>
            <.link
              patch={~p"/admin/users"}
              class="px-4 py-2 text-sm font-medium text-ok-purple-600 hover:text-ok-purple-800"
            >
              Cancel
            </.link>
          </div>
        </.form>
      </div>

      <div class="overflow-hidden rounded-lg border border-zinc-200 bg-surface-sheet shadow-sheet">
        <table class="min-w-full divide-y divide-zinc-200">
          <thead class="bg-surface-sheet-secondary">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Email
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Name
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Role
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Status
              </th>
              <th class="px-6 py-3 text-right text-xs font-medium text-zinc-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-200">
            <tr :for={user <- @users} class="hover:bg-surface-sheet-secondary">
              <td class="px-6 py-4 whitespace-nowrap text-sm text-text-dark">
                {user.email}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-600">
                {user.name || "-"}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class={[
                  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
                  user.role == "super_admin" && "bg-ok-purple-100 text-ok-purple-800",
                  user.role == "session_manager" && "bg-ok-blue-100 text-ok-blue-800"
                ]}>
                  {format_role(user.role)}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class={[
                  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
                  user.enabled && "bg-ok-green-100 text-ok-green-800",
                  !user.enabled && "bg-ok-red-100 text-ok-red-800"
                ]}>
                  {if user.enabled, do: "Enabled", else: "Disabled"}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                <.link
                  patch={~p"/admin/users/#{user.id}/edit"}
                  class="text-ok-purple-600 hover:text-ok-purple-800"
                >
                  Edit
                </.link>
                <button
                  :if={user.id != @current_scope.user.id}
                  phx-click="toggle_enabled"
                  phx-value-id={user.id}
                  class={[
                    "text-sm",
                    user.enabled && "text-ok-red-600 hover:text-ok-red-800",
                    !user.enabled && "text-ok-green-600 hover:text-ok-green-800"
                  ]}
                >
                  {if user.enabled, do: "Disable", else: "Enable"}
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
  def handle_event("save_user", %{"user" => params}, socket) do
    if socket.assigns.editing_user do
      update_user(socket, params)
    else
      create_user(socket, params)
    end
  end

  def handle_event("toggle_enabled", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    result =
      if user.enabled do
        Accounts.disable_user(user)
      else
        Accounts.enable_user(user)
      end

    case result do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully.")
         |> assign(:users, Accounts.list_users())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update user.")}
    end
  end

  defp create_user(socket, params) do
    case Accounts.create_session_manager(params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created successfully. They can log in with the magic link.")
         |> assign(:users, Accounts.list_users())
         |> push_patch(to: ~p"/admin/users")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, format_errors(changeset))
         |> assign(:form, to_form(params, as: "user"))}
    end
  end

  defp update_user(socket, params) do
    user = socket.assigns.editing_user
    attrs = %{name: params["name"], role: params["role"]}

    case Accounts.update_user(user, attrs) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully.")
         |> assign(:users, Accounts.list_users())
         |> push_patch(to: ~p"/admin/users")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, format_errors(changeset))
         |> assign(:form, to_form(params, as: "user"))}
    end
  end

  defp format_role("super_admin"), do: "Super Admin"
  defp format_role("session_manager"), do: "Session Manager"
  defp format_role(role), do: role

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &interpolate_error/1)
    |> Enum.map_join("; ", fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
  end

  defp interpolate_error({msg, opts}) do
    Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end
end
