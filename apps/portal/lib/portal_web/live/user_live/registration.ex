defmodule PortalWeb.UserLive.Registration do
  use PortalWeb, :live_view

  alias Portal.Accounts
  alias Portal.Accounts.User
  alias Portal.Tools

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <div class="text-center">
        <.header>
          Start running workshops with OOSTKit
          <:subtitle>
            Create your facilitator account to access the full toolkit. <br />
            Already have an account?
            <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
              Log in
            </.link>
          </:subtitle>
        </.header>
      </div>

      <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
        <.field
          field={@form[:name]}
          type="text"
          label="Your name"
          autocomplete="name"
          required
          phx-mounted={JS.focus()}
        />

        <.field
          field={@form[:email]}
          type="email"
          label="Email"
          autocomplete="username"
          required
        />

        <.field
          field={@form[:organisation]}
          type="text"
          label="Organisation"
          placeholder="Where do you work? (optional)"
        />

        <.field
          field={@form[:referral_source]}
          type="text"
          label="How did you hear about OOSTKit?"
          placeholder="e.g. colleague, conference, search (optional)"
        />

        <fieldset class="mt-4">
          <legend class="block text-sm font-medium text-zinc-700 mb-2">
            Which tools are you interested in?
          </legend>
          <div class="grid grid-cols-1 gap-2 sm:grid-cols-2">
            <label :for={tool <- @tools} class="flex items-center gap-2 text-sm text-zinc-700">
              <input
                type="checkbox"
                name="tool_ids[]"
                value={tool.id}
                class="rounded border-zinc-300 text-ok-purple-600 focus:ring-ok-purple-400"
              />
              {tool.name}
            </label>
          </div>
        </fieldset>

        <.button phx-disable-with="Creating account..." class="btn btn-primary w-full mt-6">
          Get started
        </.button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: PortalWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{}, %{}, validate_unique: false)

    {:ok,
     socket
     |> assign(:tools, Tools.list_tools())
     |> assign_form(changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params} = params, socket) do
    tool_ids = Map.get(params, "tool_ids", [])

    case Accounts.register_user(user_params, tool_ids) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
