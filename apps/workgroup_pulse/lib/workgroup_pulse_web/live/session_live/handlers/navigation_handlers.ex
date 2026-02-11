defmodule WorkgroupPulseWeb.SessionLive.Handlers.NavigationHandlers do
  @moduledoc """
  Handlers for workshop flow and navigation events:
  start, intro, carousel, phase transitions, go back.
  """

  import Phoenix.Component, only: [assign: 2]
  import Phoenix.LiveView, only: [push_navigate: 2]

  alias WorkgroupPulse.Sessions
  alias WorkgroupPulseWeb.SessionLive.Helpers.DataLoaders
  alias WorkgroupPulseWeb.SessionLive.TimerHandler

  import WorkgroupPulseWeb.SessionLive.OperationHelpers

  def handle_start_workshop(socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    if participant.is_facilitator do
      handle_operation(
        socket,
        Sessions.start_session(session),
        "Failed to start workshop",
        fn socket, updated_session ->
          socket
          |> assign(session: updated_session)
          |> assign(carousel_index: 0)
          |> DataLoaders.load_scoring_data(updated_session, participant)
        end
      )
    else
      {:noreply, socket}
    end
  end

  def handle_intro_next(socket) do
    current = socket.assigns.carousel_index
    {:noreply, assign(socket, carousel_index: min(current + 1, 3))}
  end

  def handle_intro_prev(socket) do
    current = socket.assigns.carousel_index
    {:noreply, assign(socket, carousel_index: max(current - 1, 0))}
  end

  @doc """
  Handles skip_intro and continue_to_scoring events.
  Navigates locally to the scoring sheet. Starts the timer for the facilitator
  on first arrival.
  """
  def handle_skip_intro(socket) do
    socket = assign(socket, carousel_index: 4)

    socket =
      if socket.assigns.participant.is_facilitator and not socket.assigns.timer_enabled do
        TimerHandler.start_phase_timer(socket, socket.assigns.session)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_carousel_navigate(socket, "workshop-carousel", index) do
    {:noreply, assign(socket, carousel_index: String.to_integer(to_string(index)))}
  end

  def handle_carousel_navigate(socket, _carousel, _index) do
    {:noreply, socket}
  end

  def handle_continue_past_transition(socket) do
    {:noreply, assign(socket, show_mid_transition: false)}
  end

  def handle_next_question(socket) do
    do_advance_to_next_question(socket, socket.assigns.participant.is_facilitator)
  end

  def handle_continue_to_wrapup(socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    if participant.is_facilitator do
      handle_operation(
        socket,
        Sessions.advance_to_completed(session),
        "Failed to advance to wrap-up",
        fn socket, updated_session ->
          socket
          |> assign(session: updated_session)
          |> assign(carousel_index: 6)
          |> DataLoaders.load_summary_data(updated_session)
          |> TimerHandler.stop_timer()
        end
      )
    else
      {:noreply, socket}
    end
  end

  def handle_finish_workshop(socket) do
    if socket.assigns.participant.is_facilitator do
      {:noreply, push_navigate(socket, to: "/")}
    else
      {:noreply, socket}
    end
  end

  @doc """
  Handles go_back event.
  Only facilitator can navigate back to keep all participants in sync.
  """
  def handle_go_back(socket) do
    if socket.assigns.participant.is_facilitator do
      do_go_back(socket)
    else
      {:noreply, socket}
    end
  end

  # Private helpers

  defp do_go_back(socket) do
    session = socket.assigns.session
    do_go_back_from_state(socket, session, session.state)
  end

  defp do_go_back_from_state(socket, %{current_question_index: 0}, "scoring") do
    {:noreply, socket}
  end

  defp do_go_back_from_state(socket, session, "scoring") do
    Sessions.reset_all_ready(session)

    handle_operation(
      socket,
      Sessions.go_back_question(session),
      "Failed to go back",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> assign(show_mid_transition: false)
        |> DataLoaders.load_scoring_data(updated_session, socket.assigns.participant)
      end
    )
  end

  defp do_go_back_from_state(socket, session, "summary") do
    Sessions.reset_all_ready(session)
    template = DataLoaders.get_or_load_template(socket, session.template_id)
    last_index = length(template.questions) - 1

    handle_operation(
      socket,
      Sessions.go_back_to_scoring(session, last_index),
      "Failed to go back",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> assign(carousel_index: 4)
        |> DataLoaders.load_scoring_data(updated_session, socket.assigns.participant)
      end
    )
  end

  defp do_go_back_from_state(socket, session, "completed") do
    Sessions.reset_all_ready(session)

    handle_operation(
      socket,
      Sessions.go_back_to_summary(session),
      "Failed to go back",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> assign(carousel_index: 5)
        |> DataLoaders.load_summary_data(updated_session)
      end
    )
  end

  defp do_go_back_from_state(socket, _session, _state) do
    {:noreply, socket}
  end

  defp do_advance_to_next_question(socket, false), do: {:noreply, socket}

  defp do_advance_to_next_question(socket, true) do
    session = socket.assigns.session
    Sessions.reset_all_ready(session)

    template = DataLoaders.get_or_load_template(socket, session.template_id)
    is_last_question = session.current_question_index + 1 >= length(template.questions)

    do_advance(socket, session, is_last_question)
  end

  defp do_advance(socket, session, true) do
    handle_operation(
      socket,
      Sessions.advance_to_summary(session),
      "Failed to advance to summary",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> assign(carousel_index: 5)
        |> DataLoaders.load_summary_data(updated_session)
        |> TimerHandler.start_phase_timer(updated_session)
      end
    )
  end

  defp do_advance(socket, session, false) do
    participant = socket.assigns.participant

    handle_operation(
      socket,
      Sessions.advance_question(session),
      "Failed to advance to next question",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> assign(show_mid_transition: false)
        |> DataLoaders.load_scoring_data(updated_session, participant)
        |> TimerHandler.start_phase_timer(updated_session)
      end
    )
  end
end
