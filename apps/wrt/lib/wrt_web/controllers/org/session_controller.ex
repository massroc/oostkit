defmodule WrtWeb.Org.SessionController do
  use WrtWeb, :controller

  alias Wrt.Auth

  plug WrtWeb.Plugs.TenantPlug

  def new(conn, _params) do
    render(conn, :new,
      page_title: "Login",
      org: conn.assigns.current_org,
      error_message: nil
    )
  end

  def create(conn, %{"admin" => %{"email" => email, "password" => password}}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    case Auth.authenticate_org_admin(tenant, email, password) do
      {:ok, admin} ->
        conn
        |> put_session(:org_admin_id, admin.id)
        |> configure_session(renew: true)
        |> put_flash(:info, "Welcome back, #{admin.name}!")
        |> redirect(to: ~p"/org/#{org.slug}/dashboard")

      {:error, _reason} ->
        render(conn, :new,
          page_title: "Login",
          org: org,
          error_message: "Invalid email or password"
        )
    end
  end

  def delete(conn, _params) do
    org = conn.assigns.current_org

    conn
    |> delete_session(:org_admin_id)
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: ~p"/org/#{org.slug}/login")
  end
end
