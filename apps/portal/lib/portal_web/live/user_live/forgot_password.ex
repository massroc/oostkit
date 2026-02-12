defmodule PortalWeb.UserLive.ForgotPassword do
  use PortalWeb, :live_view

  alias Portal.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-1 items-center justify-center py-12">
    <div class="mx-auto max-w-sm space-y-4">
      <div class="text-center">
        <.header>
          Forgot your password?
          <:subtitle>We'll send a password reset link to your email address.</:subtitle>
        </.header>
      </div>

      <.form for={@form} id="reset_password_form" phx-submit="send_email">
        <.field field={@form[:email]} type="email" label="Email" autocomplete="email" required />
        <.button class="btn btn-primary w-full">
          Send reset link <span aria-hidden="true">&rarr;</span>
        </.button>
      </.form>

      <p class="text-center text-sm">
        <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
          Back to log in
        </.link>
      </p>
    </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  @impl true
  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_password_reset_instructions(
        user,
        &url(~p"/users/reset-password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive password reset instructions shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end
end
