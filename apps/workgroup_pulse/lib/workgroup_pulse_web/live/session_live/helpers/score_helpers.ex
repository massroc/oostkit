defmodule WorkgroupPulseWeb.SessionLive.ScoreHelpers do
  @moduledoc """
  Helper functions for score display and formatting in session LiveView components.
  """

  alias WorkgroupPulse.Scoring

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
  Uses darker shades for light theme readability.
  """
  def text_color_class(:green), do: "text-traffic-green"
  def text_color_class(:amber), do: "text-amber-600"
  def text_color_class(:red), do: "text-traffic-red"
  def text_color_class(_), do: "text-gray-500"

  @doc """
  Returns CSS classes for score box background based on traffic light color.
  Light theme: colored backgrounds with matching borders.
  """
  def bg_color_class(:green), do: "bg-green-100 border-2 border-traffic-green"
  def bg_color_class(:amber), do: "bg-amber-100 border-2 border-amber-500"
  def bg_color_class(:red), do: "bg-red-100 border-2 border-traffic-red"
  def bg_color_class(_), do: "bg-gray-100 border-2 border-gray-300"

  @doc """
  Returns CSS classes for summary card background based on traffic light color.
  Light theme: subtle tinted backgrounds.
  """
  def card_color_class(:green), do: "bg-green-50 border-traffic-green"
  def card_color_class(:amber), do: "bg-amber-50 border-amber-500"
  def card_color_class(:red), do: "bg-red-50 border-traffic-red"
  def card_color_class(_), do: "bg-gray-50 border-gray-300"
end
