defmodule PortalWeb.Plugs.DevAutoLogin do
  @moduledoc """
  Dev-only plug that auto-logs in as the dev super admin on first visit.

  Skips if:
  - User is already logged in
  - `_portal_dev_visited` cookie is set (user logged out deliberately)
  """
  import Plug.Conn

  alias Portal.Accounts
  alias Portal.Accounts.Scope

  @dev_admin_email "admin@oostkit.local"
  @visited_cookie "_portal_dev_visited"
  @cross_app_cookie "_oostkit_token"

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    cond do
      conn.assigns[:current_scope] && conn.assigns.current_scope.user ->
        conn

      conn.cookies[@visited_cookie] ->
        conn

      true ->
        case Accounts.get_user_by_email(@dev_admin_email) do
          nil -> conn
          user -> auto_login(conn, user)
        end
    end
  end

  defp auto_login(conn, user) do
    token = Accounts.generate_user_session_token(user)
    encoded = Base.url_encode64(token)

    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{encoded}")
    |> put_resp_cookie(@cross_app_cookie, encoded,
      max_age: 14 * 86_400,
      same_site: "Lax",
      http_only: true
    )
    |> put_resp_cookie(@visited_cookie, "1", max_age: 86_400 * 30, same_site: "Lax")
    |> assign(:current_scope, Scope.for_user(user))
  end
end
