defmodule PortalWeb.Plugs.RequireSuperAdmin do
  @moduledoc """
  Plug that requires the current user to be a super_admin.

  Must be used after PortalWeb.UserAuth.fetch_current_scope_for_user.
  """
  import Plug.Conn
  import Phoenix.Controller

  alias Portal.Accounts.User

  def init(opts), do: opts

  def call(conn, _opts) do
    user = get_in(conn.assigns, [:current_scope, Access.key(:user)])

    if user && User.super_admin?(user) && User.enabled?(user) do
      conn
    else
      conn
      |> put_flash(:error, "You must be a super admin to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
