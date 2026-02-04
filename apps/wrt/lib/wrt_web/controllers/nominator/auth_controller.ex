defmodule WrtWeb.Nominator.AuthController do
  @moduledoc """
  Handles nominator authentication via magic links.
  """
  use WrtWeb, :controller

  def landing(conn, _params) do
    # TODO: Implement magic link landing page
    conn
    |> put_status(:not_implemented)
    |> text("Not implemented yet")
  end

  def request_link(conn, _params) do
    # TODO: Implement magic link request
    conn
    |> put_status(:not_implemented)
    |> text("Not implemented yet")
  end

  def verify(conn, _params) do
    # TODO: Implement magic link verification
    conn
    |> put_status(:not_implemented)
    |> text("Not implemented yet")
  end
end
