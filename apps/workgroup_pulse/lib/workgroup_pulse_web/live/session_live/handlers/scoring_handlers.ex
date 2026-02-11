defmodule WorkgroupPulseWeb.SessionLive.Handlers.ScoringHandlers do
  @moduledoc """
  Handlers for scoring and turn-based events:
  score submission, turn completion, skipping, readiness.
  """

  import Phoenix.Component, only: [assign: 2]
  import Phoenix.LiveView, only: [put_flash: 3]

  alias WorkgroupPulse.Scoring
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulseWeb.SessionLive.Helpers.DataLoaders

  import WorkgroupPulseWeb.SessionLive.OperationHelpers

  require Logger

  def handle_select_score(socket, params) do
    score = params["score"] || params["value"]

    int_value =
      cond do
        is_integer(score) -> score
        is_binary(score) and score != "" -> String.to_integer(score)
        true -> nil
      end

    if int_value do
      socket = assign(socket, selected_value: int_value)
      do_submit_score(socket, int_value)
    else
      {:noreply, socket}
    end
  end

  def handle_submit_score(socket) do
    do_submit_score(socket, socket.assigns.selected_value)
  end

  def handle_edit_my_score(socket) do
    if socket.assigns.is_my_turn and not socket.assigns.my_turn_locked do
      {:noreply,
       socket
       |> assign(show_score_overlay: true)
       |> assign(show_discuss_prompt: false)}
    else
      {:noreply, socket}
    end
  end

  def handle_close_score_overlay(socket) do
    {:noreply, assign(socket, show_score_overlay: false)}
  end

  def handle_complete_turn(socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant
    question_index = session.current_question_index

    case Scoring.lock_participant_turn(session, participant, question_index) do
      {:ok, _score} ->
        case Sessions.advance_turn(session) do
          {:ok, updated_session} ->
            {:noreply,
             socket
             |> assign(session: updated_session)
             |> assign(my_turn_locked: true)
             |> DataLoaders.load_scoring_data(updated_session, participant)}

          {:error, reason} ->
            Logger.error("Failed to advance turn: #{inspect(reason)}")
            {:noreply, put_flash(socket, :error, "Failed to advance turn")}
        end

      {:error, :no_score} ->
        {:noreply, put_flash(socket, :error, "Please place a score first")}
    end
  end

  def handle_skip_turn(socket) do
    participant = socket.assigns.participant

    handle_operation(
      socket,
      Sessions.skip_turn(socket.assigns.session),
      "Failed to skip turn",
      fn socket, updated_session ->
        socket
        |> assign(session: updated_session)
        |> DataLoaders.load_scoring_data(updated_session, participant)
      end
    )
  end

  def handle_mark_ready(socket) do
    participant = socket.assigns.participant

    handle_operation(
      socket,
      Sessions.set_participant_ready(participant, true),
      "Failed to mark as ready",
      &assign(&1, participant: &2)
    )
  end

  # Private helpers

  defp do_submit_score(socket, nil) do
    {:noreply, put_flash(socket, :error, "Please select a score first")}
  end

  defp do_submit_score(socket, selected_value) do
    session = socket.assigns.session
    participant = socket.assigns.participant
    question_index = session.current_question_index
    template = socket.assigns[:template]

    case Scoring.submit_score(session, participant, question_index, selected_value) do
      {:ok, _score} ->
        broadcast(session, {:score_submitted, participant.id, question_index})

        {:noreply,
         socket
         |> assign(my_score: selected_value)
         |> assign(has_submitted: true)
         |> assign(show_score_overlay: false)
         |> assign(show_discuss_prompt: true)
         |> DataLoaders.load_scores(session, question_index)
         |> DataLoaders.load_all_questions_scores(session, template)}

      {:error, reason} ->
        Logger.error("Failed to submit score: #{inspect(reason)}")
        {:noreply, put_flash(socket, :error, "Failed to submit score")}
    end
  end

  defp broadcast(session, event) do
    Phoenix.PubSub.broadcast(
      WorkgroupPulse.PubSub,
      Sessions.session_topic(session),
      event
    )
  end
end
