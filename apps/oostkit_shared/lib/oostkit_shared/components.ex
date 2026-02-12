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

  ## Slots

    * `:actions` - Content for the right side of the header (auth links, etc.)
  """
  attr :brand_url, :string, default: "/"
  attr :title, :string, default: nil
  slot :actions

  def header_bar(assigns) do
    ~H"""
    <header class="bg-ok-purple-900">
      <nav class="relative mx-auto flex max-w-7xl items-center justify-between p-4 lg:px-8">
        <a href={@brand_url} class="text-lg font-semibold text-white">
          OOSTKit
        </a>
        <span
          :if={@title}
          class="pointer-events-none absolute inset-x-0 hidden text-center font-brand text-sm font-medium text-ok-purple-200 sm:block"
        >
          {@title}
        </span>
        <div class="flex items-center gap-4">
          {render_slot(@actions)}
        </div>
      </nav>
    </header>
    <div class="brand-stripe"></div>
    """
  end
end
