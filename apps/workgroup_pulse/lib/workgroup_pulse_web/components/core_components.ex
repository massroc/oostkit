defmodule WorkgroupPulseWeb.CoreComponents do
  @moduledoc """
  Workgroup Pulse-specific UI components.

  Shared components (icon, flash, show/hide) live in `OostkitShared.Components`.
  Standard form components (button, input, field) come from Petal Components.
  """
  use Phoenix.Component
  use Gettext, backend: WorkgroupPulseWeb.Gettext

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
