defmodule PortalWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :portal

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  @session_options [
    store: :cookie,
    key: "_portal_key",
    signing_salt: "portal_signing",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  plug Plug.Static,
    at: "/",
    from: :portal,
    gzip: false,
    only: PortalWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :portal
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug PortalWeb.Plugs.RateLimiter
  plug :put_session_with_domain
  plug PortalWeb.Router

  defp put_session_with_domain(conn, _opts) do
    opts = @session_options ++ cookie_domain_opts()
    Plug.Session.call(conn, Plug.Session.init(opts))
  end

  defp cookie_domain_opts do
    case Application.get_env(:portal, :cookie_domain) do
      nil -> []
      domain -> [domain: domain]
    end
  end
end
