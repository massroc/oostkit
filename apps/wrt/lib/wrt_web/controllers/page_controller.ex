defmodule WrtWeb.PageController do
  use WrtWeb, :controller

  def home(conn, _params) do
    # Users arrive via Portal, already authenticated.
    # Redirect to admin dashboard — the auth plug there will
    # bounce unauthenticated users back to Portal.
    redirect(conn, to: ~p"/admin/dashboard")
  end
end
