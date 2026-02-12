defmodule PortalWeb.CoreComponents do
  @moduledoc """
  Portal-specific UI components.

  Shared components (icon, flash, show/hide) live in `OostkitShared.Components`.
  Standard form components (button, input, field) come from Petal Components.
  """
  use Phoenix.Component
  use Gettext, backend: PortalWeb.Gettext

  use Phoenix.VerifiedRoutes,
    endpoint: PortalWeb.Endpoint,
    router: PortalWeb.Router,
    statics: PortalWeb.static_paths()

  import OostkitShared.Components, only: [icon: 1]

  alias Portal.Tools.Tool

  @doc """
  Renders a tool card for the dashboard.

  Supports three states:
  - Live & open: full colour, Launch button
  - Coming soon: muted, "Coming soon" badge, no action
  - Live & locked: full colour, "Log in to access" or "Launch" depending on auth
  """
  attr :tool, :map, required: true
  attr :current_scope, :any, default: nil

  def tool_card(assigns) do
    assigns = assign(assigns, :status, Tool.effective_status(assigns.tool))

    ~H"""
    <div class={[
      "flex flex-col rounded-xl border p-4 transition h-[140px]",
      @status == :live && "border-zinc-200 bg-surface-sheet shadow-sheet hover:shadow-sheet-lifted",
      @status == :coming_soon && "border-zinc-200 bg-surface-sheet-secondary opacity-75",
      @status == :maintenance && "border-zinc-200 bg-surface-sheet-secondary opacity-60"
    ]}>
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-semibold text-text-dark">{@tool.name}</h3>
        <%= if @status == :live do %>
          <span class="inline-flex items-center rounded-full bg-ok-green-100 px-2 py-0.5 text-xs font-medium text-ok-green-800">
            Live
          </span>
        <% end %>
      </div>
      <p class="mt-1 flex-1 text-xs text-zinc-600 line-clamp-2">{@tool.tagline}</p>
      <div class="mt-auto flex items-center justify-between pt-2">
        <.link
          navigate={~p"/apps/#{@tool.id}"}
          class="text-xs font-medium text-ok-purple-600 hover:text-ok-purple-800"
        >
          Learn more
        </.link>
        <%= if @status == :live and @tool.url do %>
          <a
            href={@tool.url}
            class="inline-flex items-center rounded-md bg-ok-purple-600 px-2.5 py-1.5 text-xs font-semibold text-white shadow-sm hover:bg-ok-purple-700"
          >
            Launch <.icon name="hero-arrow-top-right-on-square" class="ml-1 h-3.5 w-3.5" />
          </a>
        <% else %>
          <span class="inline-flex items-center rounded-full bg-ok-gold-100 px-2 py-0.5 text-xs font-medium text-ok-gold-800">
            Coming soon
          </span>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders an empty state message.
  """
  slot :inner_block, required: true

  def empty_state(assigns) do
    ~H"""
    <div class="rounded-lg border border-dashed border-zinc-300 bg-surface-sheet-secondary p-6 text-center">
      <p class="text-sm text-zinc-500">{render_slot(@inner_block)}</p>
    </div>
    """
  end

  @doc """
  Renders a simple form.
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders the site-wide footer bar.

  Left side: brand name + tagline. Right side: navigation links.
  """
  def footer_bar(assigns) do
    ~H"""
    <footer class="border-t border-zinc-200 bg-surface-sheet-secondary">
      <div class="mx-auto flex max-w-7xl items-center justify-between px-6 py-6 lg:px-8">
        <div class="flex items-center gap-2 text-sm">
          <span class="font-semibold text-text-dark">OOSTKit</span>
          <span class="text-zinc-300">&middot;</span>
          <span class="text-zinc-500">Online OST Kit</span>
        </div>
        <nav class="flex items-center gap-6 text-sm">
          <.link navigate={~p"/about"} class="text-zinc-500 hover:text-text-dark">
            About Us
          </.link>
          <.link navigate={~p"/privacy"} class="text-zinc-500 hover:text-text-dark">
            Privacy Policy
          </.link>
          <.link navigate={~p"/contact"} class="text-zinc-500 hover:text-text-dark">
            Contact Us
          </.link>
        </nav>
      </div>
    </footer>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(PortalWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(PortalWeb.Gettext, "errors", msg, opts)
    end
  end
end
