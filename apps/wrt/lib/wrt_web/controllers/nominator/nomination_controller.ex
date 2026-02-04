defmodule WrtWeb.Nominator.NominationController do
  @moduledoc """
  Handles nomination form and submission.
  """
  use WrtWeb, :controller

  def edit(conn, _params) do
    # TODO: Implement nomination form
    conn
    |> put_status(:not_implemented)
    |> text("Not implemented yet")
  end

  def submit(conn, _params) do
    # TODO: Implement nomination submission
    conn
    |> put_status(:not_implemented)
    |> text("Not implemented yet")
  end
end
