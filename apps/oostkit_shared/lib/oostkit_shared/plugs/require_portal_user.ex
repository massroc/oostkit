defmodule OostkitShared.Plugs.RequirePortalUser do
  @moduledoc """
  Requires the user to be authenticated via Portal (any role).

  Portal sets the `_oostkit_token` cookie, which is validated by the
  `OostkitShared.Plugs.PortalAuth` plug upstream. This plug checks
  that a valid, enabled user exists.

  ## Configuration

      config :oostkit_shared, :portal_auth,
        login_url: "https://oostkit.com/users/log-in"

  ## Options

    * `:endpoint` - The app's endpoint module, used to build the return URL.
      Required.

  """

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, opts) do
    case conn.assigns[:portal_user] do
      %{"enabled" => true} ->
        conn

      _ ->
        config = Application.get_env(:oostkit_shared, :portal_auth, [])

        portal_login_url =
          Keyword.get(config, :login_url, "https://oostkit.com/users/log-in")

        endpoint = Keyword.fetch!(opts, :endpoint)
        current_url = endpoint.url() <> current_path(conn)

        redirect_url =
          portal_login_url <> "?" <> URI.encode_query(%{"return_to" => current_url})

        conn
        |> put_flash(:error, "You must be logged in via OOSTKit Portal to access this page.")
        |> redirect(external: redirect_url)
        |> halt()
    end
  end
end
