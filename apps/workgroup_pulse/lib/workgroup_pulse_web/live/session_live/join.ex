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
    <div class="flex-1 flex flex-col items-center justify-center px-4 py-8">
      <.sheet class="shadow-sheet p-sheet-padding w-[520px]">
        <div class="text-center mb-5">
          <.link
            navigate={~p"/"}
            class="text-ink-blue/50 hover:text-ink-blue inline-flex items-center text-sm font-brand mb-4"
          >
            <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M10 19l-7-7m0 0l7-7m-7 7h18"
              />
            </svg>
            Back
          </.link>

          <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-1">
            Join Workshop
          </h1>
          <p class="text-ink-blue/60 text-sm font-brand">
            Session
            <span class="font-mono text-ink-blue font-bold tracking-wider">{@session.code}</span>
          </p>
        </div>

        <form
          id="join-form"
          action={~p"/session/#{@session.code}/join"}
          method="post"
          class="space-y-4"
        >
          <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
          <div>
            <label
              for="participant_name"
              class="block text-xs font-semibold text-ink-blue/70 mb-1.5 font-brand uppercase tracking-wide"
            >
              Your Name
            </label>
            <input
              type="text"
              name="participant[name]"
              id="participant_name"
              value={@form[:name].value}
              placeholder="Enter your name"
              class="w-full bg-surface-wall border border-ink-blue/10 rounded-lg px-4 py-2.5 text-ink-blue placeholder-ink-blue/30 focus:ring-2 focus:ring-accent-purple focus:border-transparent font-workshop text-xl"
              autofocus
            />
            <%= if @form[:name].errors != [] do %>
              <p class="mt-1.5 text-xs text-accent-red font-brand">
                <%= for {msg, _opts} <- @form[:name].errors do %>
                  {msg}
                <% end %>
              </p>
            <% end %>
          </div>

          <button
            type="submit"
            class="w-full btn-workshop btn-workshop-primary text-base py-3"
          >
            Join Workshop
          </button>
        </form>

        <p class="text-ink-blue/40 text-xs text-center mt-4 font-brand">
          You'll join once the facilitator starts the session.
        </p>
      </.sheet>
    </div>
    """
  end
end
