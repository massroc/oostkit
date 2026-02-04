defmodule WrtWeb.WebhookController do
  @moduledoc """
  Handles webhooks from email providers (Postmark, SendGrid).
  """
  use WrtWeb, :controller

  def email(conn, _params) do
    # TODO: Implement email webhook processing
    conn
    |> put_status(:ok)
    |> json(%{status: "received"})
  end
end
