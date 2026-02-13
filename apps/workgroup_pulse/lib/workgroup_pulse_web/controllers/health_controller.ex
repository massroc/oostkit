defmodule WorkgroupPulseWeb.HealthController do
  @moduledoc """
  Health check endpoints for load balancers and monitoring.
  """
  use WorkgroupPulseWeb, :controller

  alias OostkitShared.HealthChecks

  def index(conn, _params) do
    HealthChecks.liveness(conn)
  end

  def ready(conn, _params) do
    checks = %{
      database: HealthChecks.check_database(WorkgroupPulse.Repo)
    }

    HealthChecks.readiness(conn, checks)
  end
end
