defmodule WrtWeb.SuperAdmin.OrgHTML do
  use WrtWeb, :html

  embed_templates "org_html/*"

  def status_badge(assigns) do
    color_class =
      case assigns.status do
        "pending" -> "bg-ok-gold-100 text-ok-gold-800"
        "approved" -> "bg-ok-green-100 text-ok-green-800"
        "rejected" -> "bg-ok-red-100 text-ok-red-800"
        "suspended" -> "bg-gray-100 text-gray-800"
        _ -> "bg-gray-100 text-gray-800"
      end

    assigns = assign(assigns, :color_class, color_class)

    ~H"""
    <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{@color_class}"}>
      {@status}
    </span>
    """
  end
end
