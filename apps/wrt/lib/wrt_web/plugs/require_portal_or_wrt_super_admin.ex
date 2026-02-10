defmodule WrtWeb.Plugs.RequirePortalOrWrtSuperAdmin do
  @moduledoc """
  Transitional plug that accepts either a Portal super_admin (from
  `conn.assigns.portal_user`) or WRT's existing super_admin session.

  This allows gradual migration from WRT-native admin auth to Portal-based auth.
  Once all admins use Portal, this can be replaced with a Portal-only check.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Wrt.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    case check_auth(conn) do
      {:ok, conn} ->
        conn

      :unauthorized ->
        portal_login_url =
          Application.get_env(:wrt, :portal_login_url, "/admin/login")

        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: portal_login_url)
        |> halt()
    end
  end

  defp check_auth(conn) do
    if portal_super_admin?(conn) do
      {:ok, conn}
    else
      case wrt_super_admin(conn) do
        {:ok, conn} -> {:ok, conn}
        :error -> :unauthorized
      end
    end
  end

  defp portal_super_admin?(conn) do
    case conn.assigns[:portal_user] do
      %{"role" => "super_admin", "enabled" => true} -> true
      _ -> false
    end
  end

  defp wrt_super_admin(conn) do
    with admin_id when not is_nil(admin_id) <- get_session(conn, :super_admin_id),
         {:ok, admin} <- Auth.verify_super_admin_session_token("session", admin_id) do
      {:ok, assign(conn, :current_super_admin, admin)}
    else
      _ -> :error
    end
  end
end
