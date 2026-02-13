defmodule PortalWeb.HealthController do
  @moduledoc """
  Health check endpoints for load balancers and monitoring.
  """
  use PortalWeb, :controller

  alias OostkitShared.HealthChecks

  def index(conn, _params) do
    HealthChecks.liveness(conn)
  end

  def ready(conn, _params) do
    checks = %{
      database: HealthChecks.check_database(Portal.Repo)
    }

    HealthChecks.readiness(conn, checks)
  end
end
