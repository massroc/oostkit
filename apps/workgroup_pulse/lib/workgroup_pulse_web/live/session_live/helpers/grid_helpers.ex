defmodule WorkgroupPulseWeb.SessionLive.GridHelpers do
  @moduledoc """
  Shared helpers for scoring grid rendering used by both
  ScoringComponent and SummaryComponent.
  """

  import Phoenix.Component, only: [assign: 3]

  # Fixed number of participant column slots to maintain consistent grid width
  @grid_participant_slots 7

  # Questions that are first of a paired criterion — emit a header row before them
  @first_of_pair MapSet.new(["2a", "5a"])

  @doc """
  Returns the sub-label ("a" or "b") for paired criteria, nil otherwise.
  """
  def sub_label(question) do
    cn = question.criterion_number

    cond do
      String.ends_with?(cn, "a") -> "a"
      String.ends_with?(cn, "b") -> "b"
      true -> nil
    end
  end

  @doc """
  Returns true if this question starts a paired criterion group.
  """
  def first_of_pair?(criterion_number) do
    MapSet.member?(@first_of_pair, criterion_number)
  end

  @doc """
  Prepares common grid assigns: active_participants, balance/maximal question
  splits, empty_slots, total_cols.
  """
  def prepare_grid_assigns(assigns) do
    active_participants =
      Enum.filter(assigns.participants, fn p -> not p.is_observer end)

    balance_questions = Enum.filter(assigns.all_questions, &(&1.scale_type == "balance"))
    maximal_questions = Enum.filter(assigns.all_questions, &(&1.scale_type == "maximal"))

    empty_slots = max(@grid_participant_slots - length(active_participants), 0)
    total_cols = 1 + length(active_participants) + empty_slots

    assigns
    |> assign(:active_participants, active_participants)
    |> assign(:balance_questions, balance_questions)
    |> assign(:maximal_questions, maximal_questions)
    |> assign(:empty_slots, empty_slots)
    |> assign(:total_cols, total_cols)
  end

  @doc """
  Formats a score value for display. Balance values > 0 get a + prefix.
  """
  def format_score_value("balance", value) when value > 0, do: "+#{value}"
  def format_score_value(_, value), do: "#{value}"

  @doc """
  Formats a criterion title, wrapping long titles like "Mutual Support and Respect".
  """
  def format_criterion_title("Mutual Support and Respect") do
    Phoenix.HTML.raw("Mutual Support<br/><span style=\"padding-left:8px\">and Respect</span>")
  end

  def format_criterion_title(title), do: title
end
