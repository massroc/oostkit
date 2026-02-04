defmodule WrtWeb.Org.RoundHTML do
  use WrtWeb, :html

  embed_templates "round_html/*"

  def status_class("pending"), do: "bg-gray-100 text-gray-800"
  def status_class("active"), do: "bg-green-100 text-green-800"
  def status_class("closed"), do: "bg-blue-100 text-blue-800"
  def status_class(_), do: "bg-gray-100 text-gray-800"
end
