defmodule WorkgroupPulse.Facilitation do
  @moduledoc """
  The Facilitation context.

  Provides calculation utilities for workshop facilitation:
  - Phase naming and identification
  - Segment-based timer duration calculations
  - Suggested durations for workshop phases
  """

  alias WorkgroupPulse.Sessions.Session

  ## Phase Utilities

  @doc """
  Returns a human-readable name for a phase.
  """
  def phase_name("summary"), do: "Summary"
  def phase_name("summary_actions"), do: "Summary + Actions"

  def phase_name("question_" <> index) do
    "Question #{String.to_integer(index) + 1}"
  end

  def phase_name(phase), do: phase

  ## Segment-Based Timer Functions

  @doc """
  Calculates the base segment duration for a session's timer.

  Total session time is divided into 10 equal segments:
  - 8 segments for 8 questions (Q1 gets 2 segments, Q2-Q8 get 1 each)
  - 1 segment for Summary + Actions (combined)
  - 1 segment unallocated as flex/buffer

  Returns duration in seconds, or nil if session has no planned duration.
  """
  def calculate_segment_duration(%Session{planned_duration_minutes: nil}), do: nil

  def calculate_segment_duration(%Session{planned_duration_minutes: minutes}) do
    div(minutes * 60, 10)
  end

  @doc """
  Returns the timer phase string for the current session state.

  Timer phases map to visual display labels:
  - scoring state: "question_0" through "question_7"
  - summary state: "summary_actions" (shared timer)
  - completed state: nil (timer stops on wrap-up page)
  - other states: nil (no timer)
  """
  def current_timer_phase(%Session{state: "scoring", current_question_index: index}) do
    "question_#{index}"
  end

  def current_timer_phase(%Session{state: "summary"}) do
    "summary_actions"
  end

  def current_timer_phase(%Session{}), do: nil

  @doc """
  Returns whether the timer should be enabled for a session.

  Timer is enabled when:
  - Session has a planned duration
  - Session is in a timed state (scoring or summary)
  """
  def timer_enabled?(%Session{planned_duration_minutes: nil}), do: false

  def timer_enabled?(%Session{state: state}) when state in ["scoring", "summary"],
    do: true

  def timer_enabled?(%Session{}), do: false

  @doc """
  Returns the warning threshold in seconds (10% of segment duration).

  When remaining time drops to or below this threshold, the timer turns red.
  """
  def warning_threshold(%Session{} = session) do
    case calculate_segment_duration(session) do
      nil -> nil
      duration -> div(duration, 10)
    end
  end
end
