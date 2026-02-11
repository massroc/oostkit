defmodule PortalWeb.DevController do
  use PortalWeb, :controller

  alias Portal.Accounts

  @dev_admin_email "admin@oostkit.local"

  def admin_login(conn, _params) do
    case Accounts.get_user_by_email(@dev_admin_email) do
      nil ->
        conn
        |> put_flash(:error, "Dev admin not found. Run mix ecto.reset to seed.")
        |> redirect(to: ~p"/")

      user ->
        conn
        |> delete_resp_cookie("_portal_dev_visited")
        |> put_session(:user_return_to, "/admin")
        |> PortalWeb.UserAuth.log_in_user(user)
    end
  end
end
