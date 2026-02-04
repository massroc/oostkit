defmodule WorkgroupPulse.Timestamps do
  @moduledoc """
  Centralized timestamp utilities.
  """

  @doc """
  Returns current UTC time truncated to seconds.

  This is the standard timestamp format used throughout the application
  for database fields and comparisons.
  """
  def now, do: DateTime.utc_now() |> DateTime.truncate(:second)
end
