defmodule WrtWeb.Org.ResultsHTML do
  use WrtWeb, :html

  embed_templates "results_html/*"

  def source_class("seed"), do: "bg-blue-100 text-blue-800"
  def source_class("nominated"), do: "bg-purple-100 text-purple-800"
  def source_class(_), do: "bg-gray-100 text-gray-800"
end
