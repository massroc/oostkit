defmodule WrtWeb.HealthController do
  @moduledoc """
  Health check endpoints for load balancers and monitoring.
  """
  use WrtWeb, :controller

  alias OostkitShared.HealthChecks

  def index(conn, _params) do
    HealthChecks.liveness(conn)
  end

  def ready(conn, _params) do
    checks = %{
      database: HealthChecks.check_database(Wrt.Repo),
      oban: HealthChecks.check_process(Oban)
    }

    HealthChecks.readiness(conn, checks)
  end
end
