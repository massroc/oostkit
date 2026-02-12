defmodule WorkgroupPulseWeb.HealthController do
  @moduledoc """
  Health check endpoints for load balancers and monitoring.

  Provides:
  - /health - Basic liveness check
  - /health/ready - Readiness check including database connectivity
  """
  use WorkgroupPulseWeb, :controller

  @doc """
  Basic liveness check.
  Returns 200 if the application is running.
  """
  def index(conn, _params) do
    json(conn, %{
      status: "ok",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  @doc """
  Readiness check.
  Verifies database connectivity.
  """
  def ready(conn, _params) do
    checks = %{
      database: check_database()
    }

    all_ok = Enum.all?(checks, fn {_name, status} -> status == :ok end)

    status_code = if all_ok, do: 200, else: 503

    conn
    |> put_status(status_code)
    |> json(%{
      status: if(all_ok, do: "ready", else: "not_ready"),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      checks: format_checks(checks)
    })
  end

  defp check_database do
    WorkgroupPulse.Repo.query!("SELECT 1")
    :ok
  rescue
    _ -> :error
  end

  defp format_checks(checks) do
    Map.new(checks, fn {name, status} ->
      {name, %{status: status_string(status)}}
    end)
  end

  defp status_string(:ok), do: "ok"
  defp status_string(:error), do: "error"
end
