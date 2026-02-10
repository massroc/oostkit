defmodule WrtWeb.Org.DashboardHTML do
  use WrtWeb, :html

  embed_templates "dashboard_html/*"

  def status_class("draft"), do: "bg-gray-100 text-gray-800"
  def status_class("active"), do: "bg-ok-green-100 text-ok-green-800"
  def status_class("completed"), do: "bg-ok-blue-100 text-ok-blue-800"
  def status_class(_), do: "bg-gray-100 text-gray-800"
end
