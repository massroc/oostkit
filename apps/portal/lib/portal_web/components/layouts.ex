defmodule PortalWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use PortalWeb, :controller`.
  """
  use PortalWeb, :html

  @doc """
  The app layout wrapper for LiveViews.

  This layout handles both:
  - `@inner_content` for regular Phoenix layout usage (controllers)
  - `@inner_block` slot for LiveView layout usage
  """
  slot :inner_block

  def app(assigns) do
    ~H"""
    <main class="px-4 py-10 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-4xl">
        <.flash_group flash={@flash} />
        <%= if assigns[:inner_content] do %>
          {@inner_content}
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </div>
    </main>
    """
  end

  embed_templates "layouts/*"
end
