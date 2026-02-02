defmodule ProductiveWorkgroupsWeb.SessionLive.ScoreHelpers do
  @moduledoc """
  Helper functions for score display and formatting in session LiveView components.
  """

  alias ProductiveWorkgroups.Scoring

  @doc """
  Determines the traffic light color for a score based on question type.
  Returns :green, :amber, :red, or :gray.
  """
  def get_score_color(nil, _value), do: :gray

  def get_score_color(question, value) do
    Scoring.traffic_light_color(question.scale_type, value, question.optimal_value)
  end

  @doc """
  Formats description text by converting single newlines to spaces
  while preserving paragraph breaks (double newlines).
  """
  def format_description(nil), do: ""

  def format_description(text) do
    text
    |> String.trim()
    |> String.split(~r/\n\n+/)
    |> Enum.map_join("\n\n", fn paragraph ->
      paragraph
      |> String.replace(~r/\s*\n\s*/, " ")
      |> String.trim()
    end)
  end

  @doc """
  Returns CSS class for text color based on traffic light color.
  """
  def text_color_class(:green), do: "text-green-400"
  def text_color_class(:amber), do: "text-yellow-400"
  def text_color_class(:red), do: "text-red-400"
  def text_color_class(_), do: "text-gray-400"

  @doc """
  Returns CSS classes for score box background based on traffic light color.
  """
  def bg_color_class(:green), do: "bg-green-900/50 border border-green-700"
  def bg_color_class(:amber), do: "bg-yellow-900/50 border border-yellow-700"
  def bg_color_class(:red), do: "bg-red-900/50 border border-red-700"
  def bg_color_class(_), do: "bg-gray-700 border border-gray-600"

  @doc """
  Returns CSS classes for summary card background based on traffic light color.
  """
  def card_color_class(:green), do: "bg-green-900/20 border-green-700"
  def card_color_class(:amber), do: "bg-yellow-900/20 border-yellow-700"
  def card_color_class(:red), do: "bg-red-900/20 border-red-700"
  def card_color_class(_), do: "bg-gray-700 border-gray-600"
end
