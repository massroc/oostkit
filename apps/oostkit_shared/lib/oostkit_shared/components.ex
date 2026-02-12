defmodule OostkitShared.Components do
  @moduledoc """
  Shared UI components used across all OOSTKit apps.
  """
  use Phoenix.Component

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
end
