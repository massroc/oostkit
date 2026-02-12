defmodule OostkitShared.Components do
  @moduledoc """
  Shared UI components used across all OOSTKit apps.
  """
  use Phoenix.Component

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
