defmodule WrtWeb.Plugs.PortalAuth do
  @moduledoc """
  Plug that reads the `_oostkit_token` cookie set by Portal and validates
  it via Portal's internal API.

  Sets `:portal_user` in assigns (map with id, email, name, role, enabled)
  or `nil` if no valid token is found.
  """

  import Plug.Conn

  @cross_app_cookie "_oostkit_token"

  def init(opts), do: opts

  def call(%{assigns: %{portal_user: %{} = _already_set}} = conn, _opts) do
    # Already set (e.g., by test helper) — skip validation
    conn
  end

  def call(conn, _opts) do
    conn = fetch_cookies(conn)

    case conn.cookies[@cross_app_cookie] do
      nil ->
        assign(conn, :portal_user, nil)

      encoded_token ->
        case WrtWeb.PortalAuthClient.validate_token(encoded_token) do
          {:ok, user} -> assign(conn, :portal_user, user)
          {:error, _} -> assign(conn, :portal_user, nil)
        end
    end
  end
end
