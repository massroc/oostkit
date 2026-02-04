defmodule WrtWeb.SuperAdmin.OrgHTML do
  use WrtWeb, :html

  embed_templates "org_html/*"

  def status_badge(assigns) do
    color_class =
      case assigns.status do
        "pending" -> "bg-yellow-100 text-yellow-800"
        "approved" -> "bg-green-100 text-green-800"
        "rejected" -> "bg-red-100 text-red-800"
        "suspended" -> "bg-gray-100 text-gray-800"
        _ -> "bg-gray-100 text-gray-800"
      end

    assigns = assign(assigns, :color_class, color_class)

    ~H"""
    <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{@color_class}"}>
      <%= @status %>
    </span>
    """
  end
end
