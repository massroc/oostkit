defmodule ProductiveWorkgroupsWeb.SessionLive.TurnTimeoutHandler do
  @moduledoc """
  Automatic timeout for inactive participants during turn-based scoring.
  Only the facilitator's process tracks and triggers timeouts.
  """

  alias ProductiveWorkgroups.Sessions
  import Phoenix.Component, only: [assign: 2]
  require Logger

  # Check interval in milliseconds
  @timeout_check_interval 1000

  # Default timeout in seconds if not configured
  @default_turn_timeout_seconds 60

  @doc """
  Initialize timeout-related socket assigns with default values.
  """
  def init_timeout_assigns(socket) do
    socket
    |> assign(turn_started_at: nil)
    |> assign(turn_timeout_ref: nil)
    |> assign(turn_timeout_enabled: false)
  end

  @doc """
  Start the turn timeout timer. Only starts for facilitators when session
  is in scoring state and timeout is enabled.
  """
  def start_turn_timeout(socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    if should_track_timeout?(session, participant) do
      do_start_turn_timeout(socket, session)
    else
      socket
    end
  end

  @doc """
  Cancel the current turn timeout timer if one exists.
  """
  def cancel_turn_timeout(socket) do
    if socket.assigns[:turn_timeout_ref] do
      Process.cancel_timer(socket.assigns.turn_timeout_ref)
    end

    socket
    |> assign(turn_timeout_ref: nil)
    |> assign(turn_started_at: nil)
  end

  @doc """
  Handle timeout tick - check if turn has exceeded timeout and auto-skip if so.

  Returns one of:
  - {:continue, socket} - Continue tracking, no action needed
  - {:auto_skipped, updated_session, socket} - Turn was auto-skipped, caller should reload scoring data
  - {:noreply, socket} - Error occurred but timer continues
  """
  def handle_timeout_tick(socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    if should_track_timeout?(session, participant) do
      do_handle_timeout_tick(socket, session)
    else
      # Stop tracking if conditions no longer apply
      {:continue, cancel_turn_timeout(socket)}
    end
  end

  @doc """
  Restart timeout when turn changes (either participant advances or is skipped).
  Call this after session updates that affect turns.
  """
  def maybe_restart_on_turn_change(socket, old_session, new_session) do
    participant = socket.assigns.participant

    cond do
      # Not a facilitator - don't track
      not participant.is_facilitator ->
        socket

      # Session left scoring state - cancel timeout
      new_session.state != "scoring" ->
        cancel_turn_timeout(socket)

      # Turn changed - restart timeout
      turn_changed?(old_session, new_session) ->
        do_start_turn_timeout(socket, new_session)

      # Entered catch-up phase - cancel timeout (catch-up is self-paced)
      not old_session.in_catch_up_phase and new_session.in_catch_up_phase ->
        cancel_turn_timeout(socket)

      # No relevant change
      true ->
        socket
    end
  end

  @doc """
  Get the timeout duration in seconds from session settings.
  Returns nil if timeout is disabled.
  """
  def get_timeout_seconds(session) do
    settings = session.settings || %{}

    if timeout_enabled?(session) do
      Map.get(settings, "turn_timeout_seconds", @default_turn_timeout_seconds)
    else
      nil
    end
  end

  @doc """
  Check if timeout is enabled for the session.
  """
  def timeout_enabled?(session) do
    settings = session.settings || %{}
    Map.get(settings, "turn_timeout_enabled", true)
  end

  # Private functions

  defp should_track_timeout?(session, participant) do
    participant.is_facilitator and
      session.state == "scoring" and
      not session.in_catch_up_phase and
      timeout_enabled?(session)
  end

  defp do_start_turn_timeout(socket, session) do
    # Cancel any existing timeout
    socket = cancel_turn_timeout(socket)

    timeout_seconds = get_timeout_seconds(session)

    if timeout_seconds do
      timer_ref = Process.send_after(self(), :turn_timeout_tick, @timeout_check_interval)

      socket
      |> assign(turn_started_at: DateTime.utc_now())
      |> assign(turn_timeout_ref: timer_ref)
      |> assign(turn_timeout_enabled: true)
    else
      socket
      |> assign(turn_timeout_enabled: false)
    end
  end

  defp do_handle_timeout_tick(socket, session) do
    turn_started_at = socket.assigns.turn_started_at
    timeout_seconds = get_timeout_seconds(session)

    if turn_started_at && timeout_seconds do
      elapsed = DateTime.diff(DateTime.utc_now(), turn_started_at, :second)

      if elapsed >= timeout_seconds do
        # Time's up - auto-skip the current participant
        Logger.info("Turn timeout reached (#{elapsed}s >= #{timeout_seconds}s), auto-skipping")
        do_auto_skip(socket, session)
      else
        # Continue tracking
        timer_ref = Process.send_after(self(), :turn_timeout_tick, @timeout_check_interval)
        {:continue, assign(socket, turn_timeout_ref: timer_ref)}
      end
    else
      {:continue, cancel_turn_timeout(socket)}
    end
  end

  defp do_auto_skip(socket, session) do
    case Sessions.skip_turn(session) do
      {:ok, updated_session} ->
        # Return :auto_skipped so caller can reload scoring data
        {:auto_skipped, updated_session, socket}

      {:error, reason} ->
        Logger.error("Failed to auto-skip turn: #{inspect(reason)}")
        # Continue tracking - we'll retry next tick
        timer_ref = Process.send_after(self(), :turn_timeout_tick, @timeout_check_interval)
        {:noreply, assign(socket, turn_timeout_ref: timer_ref)}
    end
  end

  defp turn_changed?(old_session, new_session) do
    old_session.current_turn_index != new_session.current_turn_index or
      old_session.current_question_index != new_session.current_question_index
  end
end
