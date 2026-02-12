defmodule PortalWeb.UserLive.ResetPassword do
  use PortalWeb, :live_view

  alias Portal.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm space-y-4">
      <div class="text-center">
        <.header>
          Reset your password
          <:subtitle>Enter a new password below.</:subtitle>
        </.header>
      </div>

      <.form for={@form} id="reset_password_form" phx-submit="reset_password" phx-change="validate">
        <.field
          field={@form[:password]}
          type="password"
          label="New password"
          autocomplete="new-password"
          required
        />
        <.field
          field={@form[:password_confirmation]}
          type="password"
          label="Confirm new password"
          autocomplete="new-password"
        />
        <.button class="btn btn-primary w-full">Reset password</.button>
      </.form>

      <p class="text-center text-sm">
        <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
          Back to log in
        </.link>
      </p>
    </div>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      changeset = Accounts.change_user_password(user, %{}, hash_password: false)

      {:ok,
       socket
       |> assign(:user, user)
       |> assign(:token, token)
       |> assign(:form, to_form(changeset))}
    else
      {:ok,
       socket
       |> put_flash(:error, "Reset password link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_password(user_params, hash_password: false)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully. Please log in.")
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :insert))}
    end
  end
end
