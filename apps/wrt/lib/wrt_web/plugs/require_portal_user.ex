defmodule WrtWeb.Plugs.RequirePortalUser do
  @moduledoc """
  Requires the user to be authenticated via Portal (any role).

  Portal sets the `_oostkit_token` cookie, which is validated by the
  `PortalAuth` plug upstream. This plug checks that a valid user exists.
  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:portal_user] do
      %{"enabled" => true} ->
        conn

      _ ->
        portal_login_url =
          Application.get_env(:wrt, :portal_login_url, "https://oostkit.com/users/log-in")

        current_url = WrtWeb.Endpoint.url() <> current_path(conn)

        redirect_url =
          portal_login_url <> "?" <> URI.encode_query(%{"return_to" => current_url})

        conn
        |> put_flash(:error, "You must be logged in via OOSTKit Portal to access this page.")
        |> redirect(external: redirect_url)
        |> halt()
    end
  end
end
