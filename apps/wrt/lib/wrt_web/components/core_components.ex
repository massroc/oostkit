defmodule WrtWeb.CoreComponents do
  @moduledoc """
  WRT-specific UI components.

  Shared components (icon, flash, show/hide) live in `OostkitShared.Components`.
  Standard form components (button, input, field) come from Petal Components.
  """
  use Phoenix.Component
  use Gettext, backend: WrtWeb.Gettext

  import PetalComponents.Badge
  import PetalComponents.Button, only: [button: 1]
  import OostkitShared.Components, only: [icon: 1]

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} action={~p"/login"}>
        <.input field={@form[:email]} label="Email"/>
        <:actions>
          <.button>Log in</.button>
        </:actions>
      </.simple_form>
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
      <div class="mt-4 space-y-4">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a back navigation link.
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-8">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-ok-purple-600 hover:text-ok-purple-800"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a data table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="ID"><%= user.id %></:col>
        <:col :let={user} label="Name"><%= user.name %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class="group hover:bg-surface-sheet-secondary"
          >
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-surface-sheet-secondary sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-surface-sheet-secondary sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-ok-purple-600 hover:text-ok-purple-800"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(WrtWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(WrtWeb.Gettext, "errors", msg, opts)
    end
  end

  # =============================================================================
  # Reusable UI Components
  # =============================================================================

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
    <div class="bg-surface-sheet shadow-sheet rounded-lg p-6">
      <h3 class="text-sm font-medium text-gray-500">{@label}</h3>
      <p class={["mt-2 text-3xl font-semibold", @value_color]}>{@value}</p>
      <p :if={@detail} class="mt-1 text-sm text-gray-500">{@detail}</p>
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
      <.icon :if={@icon} name={@icon} class="mx-auto h-12 w-12 text-gray-300" />
      <p class={["text-gray-500", @icon && "mt-2"]}>{@message}</p>
      <div :if={@action_text} class="mt-4">
        <.link href={@action_href}>
          <.button>{@action_text}</.button>
        </.link>
      </div>
    </div>
    """
  end

  @doc """
  Renders a status badge using PetalComponents Badge with automatic color mapping.

  The `kind` determines the color scheme for each status value.

  ## Examples

      <.status_badge kind={:campaign} status="active" />
      <.status_badge kind={:round} status="closed" />
      <.status_badge kind={:source} status="seed" />
      <.status_badge kind={:contact} status="responded" />
  """
  attr :status, :string, required: true
  attr :kind, :atom, values: [:campaign, :round, :source, :contact], required: true

  def status_badge(assigns) do
    assigns =
      assigns
      |> assign(:color, badge_color(assigns.kind, assigns.status))
      |> assign(:label, String.capitalize(assigns.status))

    ~H"""
    <.badge color={@color} label={@label} size="sm" />
    """
  end

  defp badge_color(:campaign, "active"), do: "success"
  defp badge_color(:campaign, "completed"), do: "info"
  defp badge_color(:campaign, _), do: "gray"

  defp badge_color(:round, "active"), do: "success"
  defp badge_color(:round, "closed"), do: "info"
  defp badge_color(:round, _), do: "gray"

  defp badge_color(:source, "seed"), do: "info"
  defp badge_color(:source, "nominated"), do: "primary"
  defp badge_color(:source, _), do: "gray"

  defp badge_color(:contact, "responded"), do: "success"
  defp badge_color(:contact, "clicked"), do: "info"
  defp badge_color(:contact, "opened"), do: "warning"
  defp badge_color(:contact, _), do: "gray"

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
    <div class={["border rounded-lg p-6", callout_bg(@kind), @class]}>
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
  defp callout_bg(:neutral), do: "bg-gray-50 border-gray-200"

  defp callout_heading(:success), do: "text-ok-green-800"
  defp callout_heading(:warning), do: "text-ok-gold-800"
  defp callout_heading(:danger), do: "text-ok-red-800"
  defp callout_heading(:info), do: "text-ok-blue-800"
  defp callout_heading(:neutral), do: "text-gray-800"

  defp callout_text(:success), do: "text-ok-green-700"
  defp callout_text(:warning), do: "text-ok-gold-700"
  defp callout_text(:danger), do: "text-ok-red-700"
  defp callout_text(:info), do: "text-ok-blue-700"
  defp callout_text(:neutral), do: "text-gray-600"

end
