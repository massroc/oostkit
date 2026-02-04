defmodule WrtWeb.Plugs.FetchCurrentSuperAdmin do
  @moduledoc """
  Plug that fetches the current super admin from the session (if any).

  Unlike RequireSuperAdmin, this plug does not require authentication.
  It just makes the current admin available in assigns if logged in.
  """

  import Plug.Conn

  alias Wrt.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    admin_id = get_session(conn, :super_admin_id)

    if admin_id do
      case Auth.get_super_admin(admin_id) do
        nil ->
          conn
          |> delete_session(:super_admin_id)
          |> assign(:current_super_admin, nil)

        admin ->
          assign(conn, :current_super_admin, admin)
      end
    else
      assign(conn, :current_super_admin, nil)
    end
  end
end
