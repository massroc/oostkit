defmodule PortalWeb.Plugs.ApiAuth do
  @moduledoc """
  Plug that validates internal API requests using a shared API key.

  Expects an `Authorization: Bearer <api_key>` header matching the
  configured `:internal_api_key`.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    expected_key = Application.fetch_env!(:portal, :internal_api_key)

    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         true <- Plug.Crypto.secure_compare(token, expected_key) do
      conn
    else
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{error: "forbidden"}))
        |> halt()
    end
  end
end
