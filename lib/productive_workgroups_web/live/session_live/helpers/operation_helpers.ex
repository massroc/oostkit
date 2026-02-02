defmodule ProductiveWorkgroupsWeb.SessionLive.OperationHelpers do
  @moduledoc """
  Standardized error handling for context operations.
  """

  import Phoenix.LiveView, only: [put_flash: 3]
  require Logger

  @doc """
  Handles operation result with standard error pattern.

  ## Example

      handle_operation(
        socket,
        Sessions.start_session(session),
        "Failed to start workshop",
        &assign(&1, session: &2)
      )

  For operations that return something other than the updated resource,
  use `handle_operation/3` with a custom success function that ignores
  the result.
  """
  def handle_operation(socket, {:ok, result}, _error_msg, success_fn) do
    {:noreply, success_fn.(socket, result)}
  end

  def handle_operation(socket, {:error, reason}, error_msg, _success_fn) do
    Logger.error("#{error_msg}: #{inspect(reason)}")
    {:noreply, put_flash(socket, :error, error_msg)}
  end

  @doc """
  Handles operation result when you only care about success/failure,
  not the returned value.

  ## Example

      handle_operation(
        socket,
        Notes.delete_note(note),
        "Failed to delete note",
        fn socket, _result -> load_notes(socket, session, question_index) end
      )
  """
  def handle_operation_simple(socket, {:ok, _result}, _error_msg, success_fn) do
    {:noreply, success_fn.(socket)}
  end

  def handle_operation_simple(socket, {:error, reason}, error_msg, _success_fn) do
    Logger.error("#{error_msg}: #{inspect(reason)}")
    {:noreply, put_flash(socket, :error, error_msg)}
  end
end
