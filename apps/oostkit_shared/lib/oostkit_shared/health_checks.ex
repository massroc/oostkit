defmodule OostkitShared.HealthChecks do
  @moduledoc """
  Shared health check logic for liveness and readiness endpoints.

  Each app keeps a thin `HealthController` that calls these functions
  with app-specific checks (e.g., repo module, Oban process).
  """

  import Plug.Conn

  @doc """
  Returns a simple liveness response.
  """
  def liveness(conn) do
    Phoenix.Controller.json(conn, %{
      status: "ok",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  @doc """
  Returns a readiness response based on the given checks map.

  ## Example

      checks = %{
        database: OostkitShared.HealthChecks.check_database(MyApp.Repo),
        oban: OostkitShared.HealthChecks.check_process(Oban)
      }
      OostkitShared.HealthChecks.readiness(conn, checks)

  """
  def readiness(conn, checks) when is_map(checks) do
    all_ok = Enum.all?(checks, fn {_name, status} -> status == :ok end)
    status_code = if all_ok, do: 200, else: 503

    conn
    |> put_status(status_code)
    |> Phoenix.Controller.json(%{
      status: if(all_ok, do: "ready", else: "not_ready"),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      checks: Map.new(checks, fn {k, v} -> {k, %{status: to_string(v)}} end)
    })
  end

  @doc """
  Checks database connectivity by running `SELECT 1`.
  """
  def check_database(repo) do
    repo.query!("SELECT 1")
    :ok
  rescue
    _ -> :error
  end

  @doc """
  Checks if a named process is running.
  """
  def check_process(name) do
    if Process.whereis(name), do: :ok, else: :error
  end
end
