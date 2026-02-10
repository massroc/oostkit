defmodule WrtWeb.SuperAdmin.DashboardController do
  use WrtWeb, :controller

  alias Wrt.Platform

  plug :put_layout, html: {WrtWeb.Layouts, :admin}

  def index(conn, _params) do
    stats = Platform.count_organisations_by_status()
    pending_count = Map.get(stats, "pending", 0)

    render(conn, :index,
      page_title: "Dashboard",
      stats: stats,
      pending_count: pending_count
    )
  end
end
