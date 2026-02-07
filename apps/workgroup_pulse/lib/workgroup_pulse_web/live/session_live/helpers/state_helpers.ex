defmodule WorkgroupPulseWeb.SessionLive.Helpers.StateHelpers do
  @moduledoc """
  State transition helpers for the session LiveView.
  Handles logic for state changes and question transitions.
  """

  import Phoenix.Component, only: [assign: 3]

  alias WorkgroupPulseWeb.SessionLive.Helpers.DataLoaders
  alias WorkgroupPulseWeb.SessionLive.TimerHandler

  @doc """
  Handles state transitions when session state or question changes.
  Updates socket with appropriate data loading and timer management.
  """
  def handle_state_transition(socket, old_session, session) do
    state_changed = old_session.state != session.state
    question_changed = old_session.current_question_index != session.current_question_index
    turn_changed = old_session.current_turn_index != session.current_turn_index

    case {state_changed, question_changed, session.state} do
      {true, _, "intro"} ->
        assign(socket, :carousel_index, 0)

      {true, _, "scoring"} ->
        socket
        |> assign(:carousel_index, 4)
        |> DataLoaders.load_scoring_data(session, socket.assigns.participant)
        |> TimerHandler.maybe_restart_timer_on_transition(old_session, session)

      {_, true, "scoring"} ->
        socket
        |> DataLoaders.load_scoring_data(session, socket.assigns.participant)
        |> assign(:show_mid_transition, false)
        |> TimerHandler.maybe_restart_timer_on_transition(old_session, session)

      {false, false, "scoring"} when turn_changed ->
        # Turn changed within the same question - reload scoring data
        DataLoaders.load_scoring_data(socket, session, socket.assigns.participant)

      {true, _, "summary"} ->
        socket
        |> assign(:carousel_index, 5)
        |> DataLoaders.load_summary_data(session)
        |> DataLoaders.load_actions_data(session)
        |> TimerHandler.maybe_restart_timer_on_transition(old_session, session)

      {true, _, "completed"} ->
        socket
        |> assign(:carousel_index, 6)
        |> DataLoaders.load_summary_data(session)
        |> DataLoaders.load_actions_data(session)
        |> TimerHandler.stop_timer()

      _ ->
        socket
    end
  end

end
