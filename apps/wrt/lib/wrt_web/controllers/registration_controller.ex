defmodule WrtWeb.RegistrationController do
  use WrtWeb, :controller

  alias Wrt.Platform
  alias Wrt.Platform.Organisation

  def new(conn, _params) do
    changeset = Organisation.registration_changeset(%Organisation{}, %{})
    render(conn, :new, changeset: changeset, page_title: "Register Organisation")
  end

  def create(conn, %{"organisation" => org_params}) do
    case Platform.register_organisation(org_params) do
      {:ok, _org} ->
        conn
        |> put_flash(:info, "Registration submitted! You will receive an email when your organisation is approved.")
        |> redirect(to: ~p"/")

      {:error, changeset} ->
        render(conn, :new, changeset: changeset, page_title: "Register Organisation")
    end
  end
end
