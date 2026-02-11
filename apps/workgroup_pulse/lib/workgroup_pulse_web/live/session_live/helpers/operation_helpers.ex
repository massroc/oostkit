defmodule WorkgroupPulseWeb.SessionLive.OperationHelpers do
  @moduledoc """
  Standardized error handling for context operations.
  """

  import Phoenix.LiveView, only: [put_flash: 3]
  require Logger

  @doc """
  Handles operation result with standard error pattern.

  The success function can be either:
  - 2-arity: `fn socket, result -> ... end` - receives the operation result
  - 1-arity: `fn socket -> ... end` - ignores the result

  ## Examples

      # 2-arity: use the result
      handle_operation(
        socket,
        Sessions.start_session(session),
        "Failed to start workshop",
        &assign(&1, session: &2)
      )

      # 1-arity: ignore the result
      handle_operation(
        socket,
        Notes.delete_note(note),
        "Failed to delete note",
        fn socket -> load_notes(socket, session) end
      )
  """
  def handle_operation(socket, {:ok, result}, _error_msg, success_fn) do
    {:noreply, apply_success(socket, result, success_fn)}
  end

  def handle_operation(socket, {:error, reason}, error_msg, _success_fn) do
    Logger.error("#{error_msg}: #{inspect(reason)}")
    {:noreply, put_flash(socket, :error, error_msg)}
  end

  defp apply_success(socket, result, fun) when is_function(fun, 2), do: fun.(socket, result)
  defp apply_success(socket, _result, fun) when is_function(fun, 1), do: fun.(socket)
end
