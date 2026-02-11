defmodule WorkgroupPulseWeb.CoreComponents do
  @moduledoc """
  Provides core UI components for the Workgroup Pulse application.
  """
  use Phoenix.Component
  use Gettext, backend: WorkgroupPulseWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:info}
        title={gettext("Connecting")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Creating new session")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:info}
        title={gettext("Reconnecting...")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Please wait while we reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(WorkgroupPulseWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(WorkgroupPulseWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Renders a facilitator-only session timer.

  ## Attributes

  - `remaining_seconds` - Current remaining time in seconds
  - `total_seconds` - Total segment duration in seconds
  - `phase_name` - Human-readable phase name for display
  - `warning_threshold` - Seconds remaining when timer turns red (default: 10% of total)
  """
  attr :remaining_seconds, :integer, required: true
  attr :total_seconds, :integer, required: true
  attr :phase_name, :string, required: true
  attr :warning_threshold, :integer, default: nil

  def facilitator_timer(assigns) do
    threshold = assigns.warning_threshold || div(assigns.total_seconds, 10)
    is_warning = assigns.remaining_seconds <= threshold

    assigns =
      assigns
      |> assign(:is_warning, is_warning)
      |> assign(:formatted_time, format_timer_time(assigns.remaining_seconds))

    ~H"""
    <div
      id="facilitator-timer"
      phx-hook="FacilitatorTimer"
      data-remaining={@remaining_seconds}
      data-total={@total_seconds}
      data-threshold={@warning_threshold || div(@total_seconds, 10)}
      class={[
        "fixed top-4 right-4 z-40 rounded-lg px-4 py-2 shadow-lg",
        "flex flex-col items-center transition-colors duration-300",
        if(@is_warning,
          do: "bg-red-900/90 border border-red-600",
          else: "bg-gray-800/90 border border-gray-600"
        )
      ]}
    >
      <div class="text-xs text-gray-400 mb-0.5">Time for this section</div>
      <div class={[
        "text-2xl font-mono font-bold tabular-nums",
        if(@is_warning, do: "text-red-400", else: "text-white")
      ]}>
        {@formatted_time}
      </div>
      <div class="text-xs text-gray-400">{@phase_name}</div>
    </div>
    """
  end

  defp format_timer_time(seconds) when seconds < 0, do: "0:00"

  defp format_timer_time(seconds) do
    mins = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{mins}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # Sheet Carousel Design System Components
  # ═══════════════════════════════════════════════════════════════════════════

  @doc """
  Renders the OOSTKit app header with brand link and session name.

  ## Examples

      <.app_header session_name="Team Alpha — Six Criteria" />
  """
  attr :session_name, :string, default: nil

  def app_header(assigns) do
    ~H"""
    <header class="bg-ok-purple-900 flex-shrink-0 z-10">
      <nav class="mx-auto flex max-w-7xl items-center justify-between p-4 lg:px-8">
        <a href="https://oostkit.com" class="text-lg font-semibold text-white">
          OOSTKit
        </a>
        <div class="flex items-center gap-4">
          <span :if={@session_name} class="text-sm text-ok-purple-200">
            {@session_name}
          </span>
          <span class="text-sm text-ok-purple-300">Workgroup Pulse</span>
        </div>
      </nav>
    </header>
    <div class="brand-stripe"></div>
    """
  end

  @doc """
  Renders a sheet - the core UI primitive of the carousel design system.

  ## Examples

      <.sheet class="shadow-sheet p-6 max-w-2xl w-full">
        <h1>Content</h1>
      </.sheet>

      <.sheet variant={:secondary} class="shadow-sheet p-4 w-[280px]">
        <h2>Notes</h2>
      </.sheet>
  """
  attr :variant, :atom, values: [:primary, :secondary], default: :primary
  attr :class, :any, default: nil
  attr :style, :string, default: "transform: rotate(-0.2deg)"
  attr :rest, :global

  slot :inner_block, required: true

  def sheet(assigns) do
    ~H"""
    <div
      class={[
        if(@variant == :primary, do: "paper-texture", else: "paper-texture-secondary"),
        "rounded-sheet",
        @class
      ]}
      style={@style}
      {@rest}
    >
      <div class="relative z-[1]">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
