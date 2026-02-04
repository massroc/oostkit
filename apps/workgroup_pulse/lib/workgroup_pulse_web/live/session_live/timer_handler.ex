defmodule WorkgroupPulseWeb.SessionLive.TimerHandler do
  @moduledoc """
  Timer management for facilitator countdown during workshop phases.
  """

  alias WorkgroupPulse.Facilitation
  import Phoenix.Component, only: [assign: 2]

  # Timer tick interval in milliseconds
  @timer_tick_interval 1000

  @doc """
  Initialize timer-related socket assigns with default values.
  """
  def init_timer_assigns(socket) do
    socket
    |> assign(timer_enabled: false)
    |> assign(segment_duration: nil)
    |> assign(timer_remaining: nil)
    |> assign(timer_phase: nil)
    |> assign(timer_phase_name: nil)
    |> assign(timer_ref: nil)
    |> assign(timer_warning_threshold: nil)
  end

  @doc """
  Conditionally start the timer if the participant is a facilitator
  and timer is enabled for the session.
  """
  def maybe_start_timer(socket) do
    session = socket.assigns.session
    participant = socket.assigns.participant

    if participant.is_facilitator and Facilitation.timer_enabled?(session) do
      start_phase_timer(socket, session)
    else
      socket
    end
  end

  @doc """
  Start the phase timer for the current session state.
  Cancels any existing timer before starting a new one.
  """
  def start_phase_timer(socket, session) do
    # Cancel any existing timer
    socket = cancel_timer(socket)

    segment_duration = Facilitation.calculate_segment_duration(session)
    timer_phase = Facilitation.current_timer_phase(session)
    warning_threshold = Facilitation.warning_threshold(session)

    if segment_duration && timer_phase do
      # Schedule the first tick
      timer_ref = Process.send_after(self(), :timer_tick, @timer_tick_interval)

      socket
      |> assign(timer_enabled: true)
      |> assign(segment_duration: segment_duration)
      |> assign(timer_remaining: segment_duration)
      |> assign(timer_phase: timer_phase)
      |> assign(timer_phase_name: Facilitation.phase_name(timer_phase))
      |> assign(timer_ref: timer_ref)
      |> assign(timer_warning_threshold: warning_threshold)
    else
      socket
      |> assign(timer_enabled: false)
    end
  end

  @doc """
  Cancel the current timer if one exists.
  """
  def cancel_timer(socket) do
    if socket.assigns[:timer_ref] do
      Process.cancel_timer(socket.assigns.timer_ref)
    end

    assign(socket, timer_ref: nil)
  end

  @doc """
  Handle timer tick - decrement remaining time and schedule next tick.
  Returns {:noreply, socket} for direct use in handle_info.
  """
  def handle_timer_tick(socket) do
    if socket.assigns.timer_enabled and socket.assigns.timer_remaining > 0 do
      new_remaining = socket.assigns.timer_remaining - 1
      timer_ref = Process.send_after(self(), :timer_tick, @timer_tick_interval)

      {:noreply,
       socket
       |> assign(timer_remaining: new_remaining)
       |> assign(timer_ref: timer_ref)}
    else
      {:noreply, assign(socket, timer_ref: nil)}
    end
  end

  @doc """
  Restart timer on state transition if the phase changes.
  Only applies to facilitators.
  """
  def maybe_restart_timer_on_transition(socket, old_session, session) do
    participant = socket.assigns.participant

    if participant.is_facilitator do
      old_phase = Facilitation.current_timer_phase(old_session)
      new_phase = Facilitation.current_timer_phase(session)

      # Only restart if the phase actually changed
      # (summary->actions keeps the same "summary_actions" phase, so no restart)
      if old_phase != new_phase and Facilitation.timer_enabled?(session) do
        start_phase_timer(socket, session)
      else
        socket
      end
    else
      socket
    end
  end

  @doc """
  Stop the timer completely and disable it.
  """
  def stop_timer(socket) do
    socket
    |> cancel_timer()
    |> assign(timer_enabled: false)
  end
end
