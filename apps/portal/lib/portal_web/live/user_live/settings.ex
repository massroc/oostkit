defmodule PortalWeb.UserLive.Settings do
  use PortalWeb, :live_view

  alias Portal.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-6 py-8 sm:px-8">
      <div class="space-y-10">
        <div class="text-center">
          <.header>
            Account Settings
            <:subtitle>Manage your account details</:subtitle>
          </.header>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12 gap-y-10">
          <section>
            <h2 class="text-base font-semibold text-text-dark">Profile</h2>
            <.form
              for={@profile_form}
              id="profile_form"
              phx-submit="update_profile"
              phx-change="validate_profile"
            >
              <div class="mt-4 space-y-4 max-w-xs">
                <.field
                  field={@profile_form[:name]}
                  type="text"
                  label="Name"
                  autocomplete="name"
                  required
                />
                <.field
                  field={@profile_form[:organisation]}
                  type="text"
                  label="Organisation (optional)"
                  autocomplete="organization"
                />
              </div>
              <div class="mt-6">
                <.button phx-disable-with="Saving...">Save Profile</.button>
              </div>
            </.form>
          </section>

          <section>
            <h2 class="text-base font-semibold text-text-dark">Contact Preferences</h2>
            <.form
              for={@contact_prefs_form}
              id="contact_prefs_form"
              phx-submit="update_contact_prefs"
              phx-change="validate_contact_prefs"
            >
              <div class="mt-4">
                <.field
                  field={@contact_prefs_form[:product_updates]}
                  type="checkbox"
                  label="Product updates"
                />
              </div>
              <div class="mt-6">
                <.button phx-disable-with="Saving...">Save Preferences</.button>
              </div>
            </.form>
          </section>

          <section>
            <h2 class="text-base font-semibold text-text-dark">Email</h2>
            <.form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
            >
              <div class="mt-4 space-y-4 max-w-xs">
                <.field
                  field={@email_form[:email]}
                  type="email"
                  label="Email"
                  autocomplete="username"
                  required
                />
              </div>
              <div class="mt-6">
                <.button phx-disable-with="Changing...">Change Email</.button>
              </div>
            </.form>
          </section>

          <section>
            <h2 class="text-base font-semibold text-text-dark">Password</h2>
            <.form
              for={@password_form}
              id="password_form"
              action={~p"/users/update-password"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
            >
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_user_email"
                autocomplete="username"
                value={@current_email}
              />
              <div class="mt-4 space-y-4 max-w-xs">
                <.field
                  field={@password_form[:password]}
                  type="password"
                  label={@password_label}
                  autocomplete="new-password"
                  required
                />
                <.field
                  field={@password_form[:password_confirmation]}
                  type="password"
                  label="Confirm new password"
                  autocomplete="new-password"
                />
              </div>
              <div class="mt-6">
                <.button phx-disable-with="Saving...">
                  {@password_label}
                </.button>
              </div>
            </.form>
          </section>
        </div>

        <div class="border-t border-zinc-200" />

        <section>
          <h2 class="text-base font-semibold text-ok-red-600">Danger zone</h2>
          <p class="mt-1 text-sm text-zinc-500">
            Once you delete your account, there is no going back. Please be certain.
          </p>
          <.form
            for={%{}}
            id="delete_account_form"
            action={~p"/users/delete-account"}
            method="delete"
            phx-submit="delete_account"
            phx-trigger-action={@trigger_delete}
            data-confirm="Are you sure you want to delete your account? This action cannot be undone."
          >
            <div class="mt-6">
              <.button class="btn btn-error btn-soft">Delete Account</.button>
            </div>
          </.form>
        </section>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    profile_changeset = Accounts.change_user_profile(user, %{})
    contact_prefs_changeset = Accounts.change_contact_prefs(user, %{})
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)
    password_changeset = Accounts.change_user_password(user, %{}, hash_password: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:contact_prefs_form, to_form(contact_prefs_changeset))
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:password_label, password_label(user))
      |> assign(:trigger_submit, false)
      |> assign(:trigger_delete, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    profile_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", %{"user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully.")}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_contact_prefs", %{"user" => user_params}, socket) do
    contact_prefs_form =
      socket.assigns.current_scope.user
      |> Accounts.change_contact_prefs(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, contact_prefs_form: contact_prefs_form)}
  end

  def handle_event("update_contact_prefs", %{"user" => user_params}, socket) do
    user = socket.assigns.current_scope.user

    case Accounts.update_contact_prefs(user, user_params) do
      {:ok, _user} ->
        {:noreply, put_flash(socket, :info, "Contact preferences updated successfully.")}

      {:error, changeset} ->
        {:noreply, assign(socket, contact_prefs_form: to_form(changeset, action: :insert))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params

    require_sudo(socket, "change your email", fn user ->
      case Accounts.change_user_email(user, user_params) do
        %{valid?: true} = changeset ->
          Accounts.deliver_user_update_email_instructions(
            Ecto.Changeset.apply_action!(changeset, :insert),
            user.email,
            &url(~p"/users/settings/confirm-email/#{&1}")
          )

          info = "A link to confirm your email change has been sent to the new address."
          {:noreply, socket |> put_flash(:info, info)}

        changeset ->
          {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
      end
    end)
  end

  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params

    require_sudo(socket, "change your password", fn user ->
      case Accounts.change_user_password(user, user_params) do
        %{valid?: true} = changeset ->
          {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

        changeset ->
          {:noreply, assign(socket, password_form: to_form(changeset, action: :insert))}
      end
    end)
  end

  def handle_event("delete_account", _params, socket) do
    require_sudo(socket, "delete your account", fn _user ->
      {:noreply, assign(socket, trigger_delete: true)}
    end)
  end

  defp require_sudo(socket, action_name, fun) do
    user = socket.assigns.current_scope.user

    if Accounts.sudo_mode?(user) do
      fun.(user)
    else
      {:noreply,
       socket
       |> put_flash(:error, "You must re-authenticate to #{action_name}.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  defp password_label(%{hashed_password: nil}), do: "Add a password"
  defp password_label(_user), do: "Change password"
end
