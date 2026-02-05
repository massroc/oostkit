defmodule WorkgroupPulseWeb.SessionLive.Join do
  @moduledoc """
  LiveView for joining an existing workshop session.
  """
  use WorkgroupPulseWeb, :live_view

  alias WorkgroupPulse.Sessions

  @impl true
  def mount(%{"code" => code}, _session, socket) do
    case Sessions.get_session_by_code(code) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Session not found. Please check the code and try again.")
         |> redirect(to: ~p"/")}

      session ->
        changeset = participant_changeset(%{})

        {:ok,
         socket
         |> assign(page_title: "Join Workshop")
         |> assign(session: session)
         |> assign(form: to_form(changeset, as: :participant))}
    end
  end

  @impl true
  def handle_event("validate", %{"participant" => params}, socket) do
    changeset =
      participant_changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: :participant))}
  end

  defp participant_changeset(attrs) do
    types = %{name: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(attrs, Map.keys(types))
    |> Ecto.Changeset.validate_required([:name], message: "Name is required")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-surface-wall flex flex-col items-center justify-center px-4">
      <div class="max-w-md w-full">
        <.link
          navigate={~p"/"}
          class="text-text-body hover:text-text-dark mb-8 inline-flex items-center"
        >
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M10 19l-7-7m0 0l7-7m-7 7h18"
            />
          </svg>
          Back to Home
        </.link>

        <div class="bg-surface-sheet rounded-sheet shadow-sheet p-sheet-padding">
          <h1 class="text-2xl font-bold text-text-dark mb-2 text-center font-brand">
            Join Workshop
          </h1>
          <p class="text-text-body text-center mb-8">
            Session code: <span class="font-mono text-text-dark font-bold">{@session.code}</span>
          </p>

          <form
            id="join-form"
            action={~p"/session/#{@session.code}/join"}
            method="post"
            class="space-y-6"
          >
            <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
            <div>
              <label for="participant_name" class="block text-sm font-medium text-text-dark mb-2">
                Your Name
              </label>
              <input
                type="text"
                name="participant[name]"
                id="participant_name"
                value={@form[:name].value}
                placeholder="Enter your name"
                class="w-full bg-surface-wall border border-gray-300 rounded-lg px-4 py-3 text-text-dark placeholder-text-body focus:ring-2 focus:ring-accent-purple focus:border-transparent"
                autofocus
              />
              <%= if @form[:name].errors != [] do %>
                <p class="mt-2 text-sm text-accent-red">
                  <%= for {msg, _opts} <- @form[:name].errors do %>
                    {msg}
                  <% end %>
                </p>
              <% end %>
            </div>

            <button
              type="submit"
              class="w-full px-6 py-4 bg-df-green hover:bg-secondary-green-light text-white font-semibold rounded-lg transition-colors text-lg"
            >
              Join Workshop
            </button>
          </form>
        </div>

        <p class="text-text-body text-sm text-center mt-6">
          You'll be able to participate once the facilitator starts the session.
        </p>
      </div>
    </div>
    """
  end
end
