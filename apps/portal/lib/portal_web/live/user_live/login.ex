defmodule PortalWeb.UserLive.Login do
  use PortalWeb, :live_view

  alias Portal.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-1 items-center justify-center py-12">
      <div class="mx-auto max-w-sm space-y-4">
        <div class="text-center">
          <.header>
            <p>{if @current_scope, do: "Re-authenticate", else: "Welcome back"}</p>
            <:subtitle>
              <%= if @current_scope do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% else %>
                Don't have an account? <.link
                  navigate={~p"/users/register"}
                  class="font-semibold text-brand hover:underline"
                  phx-no-format
                >Sign up</.link> for an account now.
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <div :if={local_mail_adapter?()} class="alert alert-info">
          <.icon name="hero-information-circle" class="size-6 shrink-0" />
          <div>
            <p>You are running the local mail adapter.</p>
            <p>
              To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
            </p>
          </div>
        </div>

        <.form
          :let={f}
          for={@form}
          id="login_form_magic"
          action={~p"/users/log-in"}
          phx-submit="submit_magic"
        >
          <.field
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="email"
            required
            phx-mounted={JS.focus()}
          />
          <.button class="btn btn-primary w-full">
            Send me a login link <span aria-hidden="true">&rarr;</span>
          </.button>
        </.form>

        <div class="divider text-zinc-400">or use a password</div>

        <.form
          :let={f}
          for={@form}
          id="login_form_password"
          action={~p"/users/log-in"}
          phx-submit="submit_password"
          phx-trigger-action={@trigger_submit}
          class="opacity-75 focus-within:opacity-100 transition-opacity"
        >
          <.field
            readonly={!!@current_scope}
            field={f[:email]}
            type="email"
            label="Email"
            autocomplete="email"
            required
          />
          <.field
            field={@form[:password]}
            type="password"
            label="Password"
            autocomplete="current-password"
          />
          <.button
            class="btn btn-primary btn-soft w-full"
            name={@form[:remember_me].name}
            value="true"
          >
            Log in with password <span aria-hidden="true">&rarr;</span>
          </.button>
        </.form>

        <p :if={!@current_scope} class="text-center text-sm text-zinc-500">
          <.link
            navigate={~p"/users/forgot-password"}
            class="font-semibold text-brand hover:underline"
          >
            Forgot your password?
          </.link>
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:portal, Portal.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
