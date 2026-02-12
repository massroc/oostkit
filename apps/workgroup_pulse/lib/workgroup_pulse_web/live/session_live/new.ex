defmodule WorkgroupPulseWeb.SessionLive.New do
  @moduledoc """
  LiveView for creating a new workshop session as a facilitator.
  """
  use WorkgroupPulseWeb, :live_view

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]

  alias WorkgroupPulse.Workshops

  @impl true
  def mount(_params, _session, socket) do
    template = Workshops.get_template_by_slug("six-criteria")

    {:ok,
     socket
     |> assign(page_title: "New Workshop")
     |> assign(template: template)
     |> assign(facilitator_name: "")
     |> assign(facilitator_participating: true)
     |> assign(duration_option: "none")
     |> assign(custom_duration: 120)
     |> assign(timer_expanded: false)
     |> assign(error: nil)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    name = params["facilitator_name"] || socket.assigns.facilitator_name

    {:noreply,
     socket
     |> assign(facilitator_name: name)
     |> assign(error: nil)}
  end

  @impl true
  def handle_event("select_duration", %{"option" => option}, socket) do
    {:noreply, assign(socket, duration_option: option)}
  end

  @impl true
  def handle_event("toggle_participating", _params, socket) do
    {:noreply,
     assign(socket, facilitator_participating: !socket.assigns.facilitator_participating)}
  end

  @impl true
  def handle_event("toggle_timer", _params, socket) do
    {:noreply, assign(socket, timer_expanded: !socket.assigns.timer_expanded)}
  end

  defp format_duration(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)

    cond do
      hours == 0 -> "#{mins} min"
      mins == 0 -> "#{hours} hr"
      true -> "#{hours} hr #{mins} min"
    end
  end

  @impl true
  def render(assigns) do
    final_duration =
      case assigns.duration_option do
        "none" -> nil
        "custom" -> assigns.custom_duration
        option -> String.to_integer(option)
      end

    assigns = assign(assigns, :final_duration, final_duration)

    ~H"""
    <div class="flex-1 flex flex-col items-center justify-center px-4 py-4">
      <.sheet class="shadow-sheet p-sheet-padding w-[520px]">
        <div class="text-center mb-3">
          <h1 class="font-workshop text-2xl font-bold text-ink-blue mb-1">
            Workgroup Pulse
          </h1>
          <p class="text-ink-blue/60 text-sm font-brand mb-3">
            Intrinsic Motivation Assessment
          </p>
          <p class="text-ink-blue/70 text-sm font-brand">
            Create a session and share the link with your team.
            <br />No accounts required. No data is stored after session ends.
          </p>
        </div>

        <form action={~p"/session/create"} method="post" phx-change="validate" class="space-y-3">
          <input type="hidden" name="_csrf_token" value={Phoenix.Controller.get_csrf_token()} />
          <input type="hidden" name="duration" value={@final_duration || ""} />
          <input
            type="hidden"
            name="facilitator_participating"
            value={to_string(@facilitator_participating)}
          />

          <%!-- Name input --%>
          <div>
            <label
              for="facilitator_name"
              class="block text-xs font-semibold text-ink-blue/70 mb-1.5 font-brand uppercase tracking-wide"
            >
              Your Name
            </label>
            <input
              type="text"
              name="facilitator_name"
              id="facilitator_name"
              value={@facilitator_name}
              placeholder="Enter your name"
              class="w-full bg-surface-wall border border-ink-blue/10 rounded-lg px-4 py-2.5 text-ink-blue placeholder-ink-blue/30 focus:ring-2 focus:ring-accent-purple focus:border-transparent font-workshop text-xl"
              autofocus
              required
            />
          </div>

          <%!-- Role toggle --%>
          <div>
            <label class="block text-xs font-semibold text-ink-blue/70 mb-1.5 font-brand uppercase tracking-wide">
              Your Role
            </label>
            <div class="bg-surface-wall/50 rounded-lg p-1 flex gap-1">
              <button
                type="button"
                phx-click="toggle_participating"
                class={[
                  "flex-1 py-2 rounded-md text-sm font-brand font-semibold transition-all flex items-center justify-center gap-2",
                  if(@facilitator_participating,
                    do: "bg-surface-sheet text-ink-blue shadow-sm",
                    else: "text-ink-blue/50 hover:text-ink-blue/70"
                  )
                ]}
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                  />
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                Participating
              </button>
              <button
                type="button"
                phx-click="toggle_participating"
                class={[
                  "flex-1 py-2 rounded-md text-sm font-brand font-semibold transition-all flex items-center justify-center gap-2",
                  if(!@facilitator_participating,
                    do: "bg-surface-sheet text-ink-blue shadow-sm",
                    else: "text-ink-blue/50 hover:text-ink-blue/70"
                  )
                ]}
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                  />
                </svg>
                Observer
              </button>
            </div>
            <p
              :if={!@facilitator_participating}
              class="text-xs text-amber-600 mt-1.5 font-brand"
            >
              You'll need a team member to join before starting.
            </p>
          </div>

          <%!-- Timer section --%>
          <div>
            <label class="block text-xs font-semibold text-ink-blue/70 mb-1.5 font-brand uppercase tracking-wide">
              Timer
            </label>
            <button
              type="button"
              phx-click="toggle_timer"
              class="w-full px-3 py-2.5 rounded-lg border border-ink-blue/10 bg-surface-wall transition-colors flex items-center gap-3 hover:border-ink-blue/20"
            >
              <div class={[
                "w-8 h-8 rounded-md flex items-center justify-center transition-colors",
                if(@duration_option != "none",
                  do: "bg-accent-gold text-white",
                  else: "bg-ink-blue/10 text-ink-blue/40"
                )
              ]}>
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
              <span class="flex-1 text-left text-ink-blue font-brand text-sm font-medium">
                <%= case @duration_option do %>
                  <% "none" -> %>
                    No timer
                  <% "120" -> %>
                    2 hours
                  <% "210" -> %>
                    3.5 hours
                  <% "custom" -> %>
                    {format_duration(@custom_duration)}
                <% end %>
              </span>
              <svg
                class={[
                  "w-4 h-4 text-ink-blue/40 transition-transform",
                  if(@timer_expanded, do: "rotate-180")
                ]}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 9l-7 7-7-7"
                />
              </svg>
            </button>

            <%= if @timer_expanded do %>
              <div class="mt-2 space-y-2">
                <div class="grid grid-cols-4 gap-1.5">
                  <button
                    type="button"
                    phx-click="select_duration"
                    phx-value-option="none"
                    class={[
                      "py-2 rounded-md border text-center text-sm font-brand font-medium transition-all",
                      if(@duration_option == "none",
                        do: "bg-accent-gold border-accent-gold text-white",
                        else:
                          "bg-surface-wall border-ink-blue/10 text-ink-blue/70 hover:border-ink-blue/20"
                      )
                    ]}
                  >
                    Off
                  </button>
                  <button
                    type="button"
                    phx-click="select_duration"
                    phx-value-option="120"
                    class={[
                      "py-2 rounded-md border text-center text-sm font-brand font-medium transition-all",
                      if(@duration_option == "120",
                        do: "bg-accent-gold border-accent-gold text-white",
                        else:
                          "bg-surface-wall border-ink-blue/10 text-ink-blue/70 hover:border-ink-blue/20"
                      )
                    ]}
                  >
                    2 hr
                  </button>
                  <button
                    type="button"
                    phx-click="select_duration"
                    phx-value-option="210"
                    class={[
                      "py-2 rounded-md border text-center text-sm font-brand font-medium transition-all",
                      if(@duration_option == "210",
                        do: "bg-accent-gold border-accent-gold text-white",
                        else:
                          "bg-surface-wall border-ink-blue/10 text-ink-blue/70 hover:border-ink-blue/20"
                      )
                    ]}
                  >
                    3.5 hr
                  </button>
                  <button
                    type="button"
                    phx-click="select_duration"
                    phx-value-option="custom"
                    class={[
                      "py-2 rounded-md border text-center text-sm font-brand font-medium transition-all",
                      if(@duration_option == "custom",
                        do: "bg-accent-gold border-accent-gold text-white",
                        else:
                          "bg-surface-wall border-ink-blue/10 text-ink-blue/70 hover:border-ink-blue/20"
                      )
                    ]}
                  >
                    Custom
                  </button>
                </div>

                <%= if @duration_option == "custom" do %>
                  <div
                    id="duration-picker"
                    phx-hook="DurationPicker"
                    data-duration={@custom_duration}
                    class="flex items-center justify-center gap-3 bg-surface-wall rounded-lg p-3"
                  >
                    <button
                      type="button"
                      data-action="decrement"
                      class="w-9 h-9 flex-shrink-0 flex items-center justify-center bg-surface-sheet hover:bg-ink-blue/5 text-ink-blue text-lg font-bold rounded-md transition-colors select-none border border-ink-blue/10"
                    >
                      −
                    </button>
                    <div class="text-center" style="width: 120px;">
                      <div
                        data-display="formatted"
                        class="text-xl font-bold text-ink-blue whitespace-nowrap font-workshop"
                      >
                        {format_duration(@custom_duration)}
                      </div>
                      <div class="text-xs text-ink-blue/50 font-brand">
                        <span data-display="minutes">{@custom_duration}</span> minutes
                      </div>
                    </div>
                    <button
                      type="button"
                      data-action="increment"
                      class="w-9 h-9 flex-shrink-0 flex items-center justify-center bg-surface-sheet hover:bg-ink-blue/5 text-ink-blue text-lg font-bold rounded-md transition-colors select-none border border-ink-blue/10"
                    >
                      +
                    </button>
                    <input
                      type="hidden"
                      name="custom_duration"
                      data-input="duration"
                      value={@custom_duration}
                    />
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <%= if @error do %>
            <p class="text-accent-red text-sm font-brand">{@error}</p>
          <% end %>

          <button
            type="submit"
            class="w-full btn-workshop btn-workshop-primary text-base py-3"
          >
            Create Workshop
          </button>
        </form>
      </.sheet>
    </div>
    """
  end
end
