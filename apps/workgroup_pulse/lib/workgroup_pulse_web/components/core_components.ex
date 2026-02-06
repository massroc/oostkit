defmodule WorkgroupPulseWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.
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
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
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
      <div class="mt-10 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
      <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value="true"
        checked={@checked}
        class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
        {@rest}
      />
      {@label}
    </label>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
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
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
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

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
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
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
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
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

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
  Renders a dark-themed modal.

  ## Examples

      <.modal id="action-modal" show={@show_modal}>
        <h2>Modal Title</h2>
        <p>Modal content goes here</p>
      </.modal>

  JS commands for showing/hiding:

      show_modal(JS.push("open_modal"), "action-modal")
      hide_modal("action-modal")
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="bg-gray-900/80 fixed inset-0 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="relative hidden bg-gray-800 rounded-xl p-8 shadow-xl ring-1 ring-gray-700"
            >
              <button
                phx-click={JS.exec("data-cancel", to: "##{@id}")}
                type="button"
                class="absolute top-4 right-4 text-gray-400 hover:text-white flex items-center justify-center"
                aria-label={gettext("close")}
              >
                <.icon name="hero-x-mark-solid" class="h-5 w-5" />
              </button>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows a modal by ID.
  """
  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc """
  Hides a modal by ID.
  """
  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      time: 200,
      transition: {"transition-all ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
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

  The timer displays time remaining for the current phase, with a warning
  state when 10% or less of the segment duration remains.

  ## Attributes

  - `remaining_seconds` - Current remaining time in seconds
  - `total_seconds` - Total segment duration in seconds
  - `phase_name` - Human-readable phase name for display
  - `warning_threshold` - Seconds remaining when timer turns red (default: 10% of total)

  ## Examples

      <.facilitator_timer
        remaining_seconds={@timer_remaining}
        total_seconds={@segment_duration}
        phase_name={@timer_phase_name}
      />
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
  # Virtual Wall Design System Components
  # ═══════════════════════════════════════════════════════════════════════════

  @doc """
  Renders the app header bar (52px) with logo, session name, and actions.

  ## Examples

      <.app_header session_name="Team Alpha — Six Criteria" />
  """
  attr :session_name, :string, default: nil
  attr :show_settings, :boolean, default: false
  attr :show_signin, :boolean, default: false

  def app_header(assigns) do
    ~H"""
    <header class="flex items-center justify-between px-6 h-header bg-ui-header-bg border-b border-ui-border flex-shrink-0 z-10 relative gradient-stripe-header">
      <div class="flex items-center gap-2.5">
        <div class="w-[30px] h-[30px] bg-accent-purple rounded-icon flex items-center justify-center shadow-md">
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="white"
            stroke-width="2.5"
            stroke-linecap="round"
            class="w-4 h-4"
          >
            <path d="M3 6h18M3 12h18M3 18h18" />
            <circle cx="7" cy="6" r="1.5" fill="white" stroke="none" />
            <circle cx="12" cy="12" r="1.5" fill="white" stroke="none" />
            <circle cx="16" cy="18" r="1.5" fill="white" stroke="none" />
          </svg>
        </div>
        <span class="font-bold text-lg text-ui-text tracking-tight font-brand">
          Workgroup Pulse
        </span>
      </div>

      <span
        :if={@session_name}
        class="font-medium text-sm text-ui-text-muted absolute left-1/2 -translate-x-1/2"
      >
        {@session_name}
      </span>

      <div class="flex items-center gap-3.5">
        <button
          :if={@show_settings}
          type="button"
          class="p-1.5 rounded-md text-ui-text-muted hover:bg-black/5 transition-colors"
          title="Settings"
        >
          <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
          >
            <circle cx="12" cy="12" r="3" />
            <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-2 2 2 2 0 01-2-2v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83 0 2 2 0 010-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 01-2-2 2 2 0 012-2h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 010-2.83 2 2 0 012.83 0l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 012-2 2 2 0 012 2v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 0 2 2 0 010 2.83l-.06.06A1.65 1.65 0 0019.32 9a1.65 1.65 0 001.51 1H21a2 2 0 012 2 2 2 0 01-2 2h-.09a1.65 1.65 0 00-1.51 1z" />
          </svg>
        </button>
        <button
          :if={@show_signin}
          type="button"
          class="font-brand text-xs font-semibold px-3.5 py-1.5 rounded-md border border-ui-border bg-white text-ui-text hover:border-accent-purple hover:text-accent-purple transition-colors"
        >
          Sign In
        </button>
      </div>
    </header>
    """
  end

  @doc """
  Renders a paper sheet container with texture, shadow, and optional rotation.

  ## Examples

      <.sheet>
        Content goes here
      </.sheet>

      <.sheet rotation={-0.2} class="min-h-[400px]">
        Content with custom rotation
      </.sheet>
  """
  attr :rotation, :float, default: -0.2, doc: "Sheet rotation in degrees"
  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def sheet(assigns) do
    ~H"""
    <div
      class={[
        "paper-texture rounded-sheet shadow-sheet p-5 relative flex flex-col overflow-hidden transition-shadow duration-300 hover:shadow-sheet-lifted",
        @class
      ]}
      style={"transform: rotate(#{@rotation}deg)"}
      {@rest}
    >
      <div class="relative z-[1] flex-1 flex flex-col">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a secondary/side sheet for notes, positioned to peek from behind the main sheet.

  ## Examples

      <.side_sheet title="Notes">
        <p>Note content here</p>
      </.side_sheet>
  """
  attr :title, :string, default: "Notes"
  attr :rotation, :float, default: 1.2, doc: "Sheet rotation in degrees"
  attr :class, :string, default: nil

  slot :inner_block, required: true

  def side_sheet(assigns) do
    ~H"""
    <div
      class={[
        "paper-texture-secondary rounded-sheet shadow-sheet p-4 relative cursor-pointer transition-shadow duration-300 hover:shadow-sheet-lifted overflow-hidden",
        @class
      ]}
      style={"transform: rotate(#{@rotation}deg)"}
    >
      <div class="relative z-[1]">
        <div class="font-workshop text-xl font-bold text-ink-blue text-center underline underline-offset-[3px] decoration-[1.5px] decoration-ink-blue/20 mb-3.5 opacity-85">
          {@title}
        </div>
        <div class="font-workshop text-base text-ink-blue leading-relaxed opacity-70">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the sheet strip navigation bar at the bottom.

  ## Examples

      <.sheet_strip current={0} total={3} />
  """
  attr :current, :integer, default: 0, doc: "Current sheet index (0-based)"
  attr :total, :integer, default: 1, doc: "Total number of sheets"
  attr :has_notes, :boolean, default: true, doc: "Whether to show notes thumbnail"

  def sheet_strip(assigns) do
    ~H"""
    <div class="h-strip bg-ui-header-bg border-t border-ui-border flex items-center px-6 gap-strip-gap flex-shrink-0 relative gradient-stripe-strip">
      <%= for i <- 0..(@total - 1) do %>
        <div class={[
          "w-strip-thumb h-strip-thumb rounded-sheet border-2 bg-surface-sheet shadow-sm cursor-pointer transition-all duration-150 hover:-translate-y-0.5 strip-thumb",
          if(i == @current, do: "border-accent-purple shadow-md active", else: "border-transparent")
        ]} />
      <% end %>

      <div
        :if={@has_notes}
        class="w-strip-thumb h-strip-thumb rounded-sheet border-2 border-transparent bg-surface-sheet-secondary shadow-sm cursor-pointer transition-all duration-150 hover:-translate-y-0.5 strip-thumb secondary"
      />

      <span class="text-[11px] text-ui-text-muted ml-2.5 font-medium">
        <span class="text-accent-gold mr-1.5 text-[8px] align-middle">●</span>
        Sheet {@current + 1} of {@total}
      </span>
    </div>
    """
  end

  @doc """
  Renders a container for floating action buttons.

  ## Examples

      <.floating_buttons>
        <.btn variant="secondary">Skip</.btn>
        <.btn variant="primary">Submit</.btn>
      </.floating_buttons>
  """
  slot :inner_block, required: true

  def floating_buttons(assigns) do
    ~H"""
    <div class="fixed bottom-[60px] right-5 flex gap-2 z-floating">
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a workshop-style button.

  ## Examples

      <.btn>Default button</.btn>
      <.btn variant="primary">Primary action</.btn>
      <.btn variant="secondary">Secondary action</.btn>
  """
  attr :type, :string, default: "button"
  attr :variant, :string, default: "secondary", values: ["primary", "secondary"]
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(phx-click phx-value-score name value form)

  slot :inner_block, required: true

  def btn(assigns) do
    ~H"""
    <button
      type={@type}
      disabled={@disabled}
      class={[
        "btn-workshop",
        @variant == "primary" && "btn-workshop-primary",
        @variant == "secondary" && "btn-workshop-secondary",
        @disabled && "opacity-50 cursor-not-allowed",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders a scoring grid table header row with participant names.

  ## Examples

      <.scoring_grid_header participants={@participants} current_turn_id={@current_turn_participant_id} />
  """
  attr :participants, :list, required: true, doc: "List of participant maps with :id and :name"
  attr :current_turn_id, :any, default: nil, doc: "ID of participant whose turn it is"

  def scoring_grid_header(assigns) do
    ~H"""
    <thead>
      <tr>
        <th class="criterion-col"></th>
        <%= for p <- @participants do %>
          <th class={[
            "participant-col font-workshop text-participant text-ink-blue",
            p.id == @current_turn_id && "active-col-header"
          ]}>
            {p.name}
          </th>
        <% end %>
      </tr>
    </thead>
    """
  end

  @doc """
  Renders a scale label row in the scoring grid.

  ## Examples

      <.scoring_grid_scale_label label="Balance Scale (−5 to +5)" colspan={6} />
  """
  attr :label, :string, required: true
  attr :colspan, :integer, required: true

  def scoring_grid_scale_label(assigns) do
    ~H"""
    <tr>
      <td class="scale-label" colspan={@colspan}>{@label}</td>
    </tr>
    """
  end

  @doc """
  Renders a criterion row in the scoring grid.

  ## Examples

      <.scoring_grid_row
        criterion_name="Elbow Room"
        parent_name={nil}
        scores={@scores}
        is_active={true}
        current_turn_id={@current_turn_id}
        scale_type="balance"
      />
  """
  attr :criterion_name, :string, required: true
  attr :parent_name, :string, default: nil

  attr :scores, :list,
    required: true,
    doc: "List of score maps with :participant_id, :value, :state"

  attr :is_active, :boolean, default: false, doc: "Whether this is the currently active row"
  attr :current_turn_id, :any, default: nil
  attr :scale_type, :string, default: "balance"

  def scoring_grid_row(assigns) do
    ~H"""
    <tr class={@is_active && "active-row"}>
      <td class="criterion">
        <span :if={@parent_name} class="parent">{@parent_name}</span>
        <span class="name">{@criterion_name}</span>
      </td>
      <%= for score <- @scores do %>
        <td class={[
          "score-cell",
          score.state == :empty && "empty",
          score.participant_id == @current_turn_id && "active-col"
        ]}>
          <%= case score.state do %>
            <% :scored -> %>
              <%= if @scale_type == "balance" and score.value > 0 do %>
                +{score.value}
              <% else %>
                {score.value}
              <% end %>
            <% :current -> %>
              ...
            <% :skipped -> %>
              ?
            <% _ -> %>
              —
          <% end %>
        </td>
      <% end %>
    </tr>
    """
  end
end
