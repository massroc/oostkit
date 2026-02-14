defmodule WrtWeb.CoreComponents do
  @moduledoc """
  WRT-specific UI components.

  Shared components (icon, flash, show/hide) live in `OostkitShared.Components`.
  Standard form components (button, input, field) come from Petal Components.
  """
  use Phoenix.Component
  use Gettext, backend: WrtWeb.Gettext

  import PetalComponents.Badge
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
end
