defmodule Wrt.Logger do
  @moduledoc """
  Structured logging helpers for the WRT application.

  Provides consistent logging for key business operations with
  structured metadata for easy searching and monitoring.
  """

  require Logger

  @doc """
  Logs a rate limit event.
  """
  def log_rate_limit(ip, path, metadata \\ %{}) do
    metadata =
      Map.merge(metadata, %{
        category: :security,
        event: :rate_limited,
        ip: format_ip(ip),
        path: path
      })

    Logger.warning("Rate limit exceeded", metadata)
  end

  defp format_ip(ip) when is_tuple(ip) do
    ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp format_ip(ip), do: inspect(ip)
end
