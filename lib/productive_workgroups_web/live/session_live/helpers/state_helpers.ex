defmodule ProductiveWorkgroupsWeb.SessionLive.Helpers.StateHelpers do
  @moduledoc """
  State transition helpers for the session LiveView.
  Handles logic for state changes and question transitions.
  """

  import Phoenix.Component, only: [assign: 3]

  alias ProductiveWorkgroupsWeb.SessionLive.Helpers.DataLoaders
  alias ProductiveWorkgroupsWeb.SessionLive.TimerHandler

  @doc """
  Handles state transitions when session state or question changes.
  Updates socket with appropriate data loading and timer management.
  """
  def handle_state_transition(socket, old_session, session) do
    state_changed = old_session.state != session.state
    question_changed = old_session.current_question_index != session.current_question_index
    turn_changed = old_session.current_turn_index != session.current_turn_index
    catch_up_changed = old_session.in_catch_up_phase != session.in_catch_up_phase

    case {state_changed, question_changed, session.state} do
      {true, _, "scoring"} ->
        socket
        |> DataLoaders.load_scoring_data(session, socket.assigns.participant)
        |> TimerHandler.maybe_restart_timer_on_transition(old_session, session)

      {_, true, "scoring"} ->
        # Load scoring data first to ensure template is available
        socket = DataLoaders.load_scoring_data(socket, session, socket.assigns.participant)
        template = socket.assigns.template

        # Show mid-workshop transition when scale type changes (e.g., balance -> maximal)
        show_transition = scale_type_changes_at?(template, old_session.current_question_index)

        socket
        |> assign(:show_mid_transition, show_transition)
        |> TimerHandler.maybe_restart_timer_on_transition(old_session, session)

      {false, false, "scoring"} when turn_changed or catch_up_changed ->
        # Turn changed within the same question - reload scoring data
        DataLoaders.load_scoring_data(socket, session, socket.assigns.participant)

      {true, _, "summary"} ->
        socket
        |> DataLoaders.load_summary_data(session)
        |> DataLoaders.load_actions_data(session)
        |> TimerHandler.maybe_restart_timer_on_transition(old_session, session)

      {true, _, "actions"} ->
        # Don't restart timer when transitioning from summary to actions - shared timer
        socket
        |> DataLoaders.load_summary_data(session)
        |> DataLoaders.load_actions_data(session)

      {true, _, "completed"} ->
        socket
        |> DataLoaders.load_summary_data(session)
        |> DataLoaders.load_actions_data(session)
        |> TimerHandler.stop_timer()

      _ ->
        socket
    end
  end

  @doc """
  Checks if advancing from current_index would cross a scale type boundary
  (e.g., from "balance" to "maximal" questions).
  """
  def scale_type_changes_at?(template, current_index) do
    current_question = Enum.find(template.questions, &(&1.index == current_index))
    next_question = Enum.find(template.questions, &(&1.index == current_index + 1))

    case {current_question, next_question} do
      {%{scale_type: current_type}, %{scale_type: next_type}} when current_type != next_type ->
        true

      _ ->
        false
    end
  end
end
