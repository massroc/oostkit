defmodule OostkitShared.Components do
  @moduledoc """
  Shared UI components used across all OOSTKit apps.
  """
  use Phoenix.Component

  import PetalComponents.Button, only: [button: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Renders the OOSTKit header bar with brand, title, and actions.

  ## Attributes

    * `:brand_url` - URL for the OOSTKit brand link. Defaults to `"/"`.
    * `:title` - Optional page/app title displayed in the center.
    * `:title_url` - Optional URL to make the center title a clickable link.
      When set, the title renders as an `<a>` tag with `pointer-events-auto`
      (overriding the container's `pointer-events-none`). When not set, the
      title renders as a static `<span>`.

  ## Slots

    * `:actions` - Content for the right side of the header (auth links, etc.)
  """
  attr :brand_url, :string, default: "/"
  attr :title, :string, default: nil
  attr :title_url, :string, default: nil
  slot :actions

  def header_bar(assigns) do
    ~H"""
    <header class="bg-ok-purple-900">
      <nav class="relative mx-auto flex max-w-7xl items-center justify-between p-4 lg:px-8">
        <a href={@brand_url} class="text-lg font-semibold text-white">
          OOSTKit
        </a>
        <div
          :if={@title}
          class="pointer-events-none absolute inset-x-0 hidden text-center sm:block"
        >
          <a
            :if={@title_url}
            href={@title_url}
            class="pointer-events-auto font-brand text-2xl font-semibold text-ok-purple-200 hover:text-white"
          >
            {@title}
          </a>
          <span
            :if={!@title_url}
            class="font-brand text-2xl font-semibold text-ok-purple-200"
          >
            {@title}
          </span>
        </div>
        <div class="flex items-center gap-4">
          {render_slot(@actions)}
        </div>
      </nav>
    </header>
    <div class="brand-stripe"></div>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-2xl font-bold text-text-dark">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
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
        @kind == :info && "bg-ok-green-50 text-ok-green-800 ring-ok-green-500 fill-ok-green-900",
        @kind == :error && "bg-ok-red-50 text-ok-red-900 shadow-md ring-ok-red-500 fill-ok-red-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label="close">
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  Includes client-error and server-error reconnection flashes for LiveView.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title="Success!" flash={@flash} />
      <.flash kind={:error} title="Error!" flash={@flash} />
      <.flash
        id="client-error"
        kind={:info}
        title="Connecting"
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        Creating new session
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:info}
        title="Reconnecting..."
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        Please wait while we reconnect
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  # =============================================================================
  # Reusable UI Components
  # =============================================================================

  @doc """
  Renders a callout box with colored background, border, optional heading, and actions.

  Covers info, success, warning, danger, and neutral (gray) variants. Use for
  status alerts, contextual messages, and action prompts.

  ## Examples

      <.callout kind={:success} heading="Active Campaign">
        <p>Campaign is running with 12 contacts.</p>
      </.callout>

      <.callout kind={:warning} heading="Ready to Start">
        <p>Your seed group has 8 people.</p>
        <:actions>
          <.link href="/rounds"><.button>Start Round 1</.button></.link>
        </:actions>
      </.callout>
  """
  attr :kind, :atom, values: [:info, :success, :warning, :danger, :neutral], required: true
  attr :heading, :string, default: nil
  attr :class, :string, default: nil

  slot :inner_block
  slot :actions

  def callout(assigns) do
    ~H"""
    <div class={["border rounded-xl p-6", callout_bg(@kind), @class]}>
      <h2 :if={@heading} class={["text-lg font-semibold", callout_heading(@kind)]}>
        {@heading}
      </h2>
      <div :if={@inner_block != []} class={[callout_text(@kind), @heading && "mt-1"]}>
        {render_slot(@inner_block)}
      </div>
      <div :if={@actions != []} class="mt-4 flex gap-4">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end

  defp callout_bg(:success), do: "bg-ok-green-50 border-ok-green-200"
  defp callout_bg(:warning), do: "bg-ok-gold-50 border-ok-gold-200"
  defp callout_bg(:danger), do: "bg-ok-red-50 border-ok-red-200"
  defp callout_bg(:info), do: "bg-ok-blue-50 border-ok-blue-200"
  defp callout_bg(:neutral), do: "bg-zinc-50 border-zinc-200"

  defp callout_heading(:success), do: "text-ok-green-800"
  defp callout_heading(:warning), do: "text-ok-gold-800"
  defp callout_heading(:danger), do: "text-ok-red-800"
  defp callout_heading(:info), do: "text-ok-blue-800"
  defp callout_heading(:neutral), do: "text-zinc-800"

  defp callout_text(:success), do: "text-ok-green-700"
  defp callout_text(:warning), do: "text-ok-gold-700"
  defp callout_text(:danger), do: "text-ok-red-700"
  defp callout_text(:info), do: "text-ok-blue-700"
  defp callout_text(:neutral), do: "text-zinc-600"

  @doc """
  Renders a stat card with label, value, optional detail, and optional link.

  ## Examples

      <.stat_card label="Response Rate" value="85%" detail="17 / 20 responded" />
      <.stat_card label="Seed Group" value="12" link_text="Manage Seed Group" link_href="/seed" />
  """
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :detail, :string, default: nil
  attr :value_color, :string, default: "text-text-dark"
  attr :link_text, :string, default: nil
  attr :link_href, :any, default: nil

  def stat_card(assigns) do
    ~H"""
    <div class="bg-surface-sheet shadow-sheet rounded-xl p-6">
      <h3 class="text-sm font-medium text-zinc-500">{@label}</h3>
      <p class={["mt-2 text-3xl font-semibold", @value_color]}>{@value}</p>
      <p :if={@detail} class="mt-1 text-sm text-zinc-500">{@detail}</p>
      <.link
        :if={@link_text}
        href={@link_href}
        class="mt-2 inline-block text-sm text-ok-purple-600 hover:text-ok-purple-800"
      >
        {@link_text} →
      </.link>
    </div>
    """
  end

  @doc """
  Renders an empty state message with optional icon and call-to-action.

  ## Examples

      <.empty_state message="No campaigns yet." />
      <.empty_state
        icon="hero-document-text"
        message="No nominations submitted yet."
        action_text="Start a Round"
        action_href="/rounds"
      />
  """
  attr :icon, :string, default: nil
  attr :message, :string, required: true
  attr :action_text, :string, default: nil
  attr :action_href, :any, default: nil

  def empty_state(assigns) do
    ~H"""
    <div class="py-8 text-center">
      <.icon :if={@icon} name={@icon} class="mx-auto h-12 w-12 text-zinc-300" />
      <p class={["text-zinc-500", @icon && "mt-2"]}>{@message}</p>
      <div :if={@action_text} class="mt-4">
        <.link href={@action_href}>
          <.button>{@action_text}</.button>
        </.link>
      </div>
    </div>
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
end
