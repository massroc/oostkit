defmodule WrtWeb.Plugs.RequireSuperAdmin do
  @moduledoc """
  Plug that ensures the current user is an authenticated super admin.

  If no super admin is logged in, redirects to the login page.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Wrt.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    with admin_id when not is_nil(admin_id) <- get_session(conn, :super_admin_id),
         {:ok, admin} <- Auth.verify_super_admin_session_token("session", admin_id) do
      conn
      |> assign(:current_super_admin, admin)
    else
      _ ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/admin/login")
        |> halt()
    end
  end
end
