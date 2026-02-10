defmodule WrtWeb.Org.ResultsHTML do
  use WrtWeb, :html

  embed_templates "results_html/*"

  def source_class("seed"), do: "bg-ok-blue-100 text-ok-blue-800"
  def source_class("nominated"), do: "bg-ok-purple-100 text-ok-purple-800"
  def source_class(_), do: "bg-gray-100 text-gray-800"
end
