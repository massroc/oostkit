defmodule PortalWeb.Api.AuthController do
  @moduledoc """
  Internal API endpoint for cross-app session token validation.

  Other apps (WRT, Pulse) call this to verify Portal session tokens.
  """

  use PortalWeb, :controller

  alias Portal.Accounts
  alias Portal.Accounts.User

  def validate(conn, %{"token" => base64_token}) do
    with {:ok, raw_token} <- Base.url_decode64(base64_token),
         {%User{enabled: true} = user, _inserted_at} <-
           Accounts.get_user_by_session_token(raw_token) do
      json(conn, %{
        valid: true,
        user: %{
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          enabled: user.enabled
        }
      })
    else
      _ ->
        conn
        |> put_status(401)
        |> json(%{valid: false, error: "invalid_token"})
    end
  end

  def validate(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{valid: false, error: "missing_token"})
  end
end
