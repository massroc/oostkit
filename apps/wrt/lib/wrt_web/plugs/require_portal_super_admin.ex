defmodule WrtWeb.Plugs.RequirePortalSuperAdmin do
  @moduledoc """
  Requires the user to be authenticated via Portal as a super_admin.

  Portal sets the `_oostkit_token` cookie, which is validated by the
  `PortalAuth` plug upstream. This plug checks that the validated user
  has the super_admin role.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:portal_user] do
      %{"role" => "super_admin", "enabled" => true} ->
        conn

      _ ->
        portal_login_url =
          Application.get_env(:wrt, :portal_login_url, "https://oostkit.com/users/log-in")

        conn
        |> put_flash(:error, "You must be logged in via OOSTKit Portal to access this page.")
        |> redirect(external: portal_login_url)
        |> halt()
    end
  end
end
