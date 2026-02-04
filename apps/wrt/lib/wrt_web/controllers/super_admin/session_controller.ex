defmodule WrtWeb.SuperAdmin.SessionController do
  use WrtWeb, :controller

  alias Wrt.Auth

  def new(conn, _params) do
    render(conn, :new, page_title: "Admin Login", error_message: nil)
  end

  def create(conn, %{"admin" => %{"email" => email, "password" => password}}) do
    case Auth.authenticate_super_admin(email, password) do
      {:ok, admin} ->
        conn
        |> put_session(:super_admin_id, admin.id)
        |> configure_session(renew: true)
        |> put_flash(:info, "Welcome back, #{admin.name}!")
        |> redirect(to: ~p"/admin/dashboard")

      {:error, _reason} ->
        render(conn, :new,
          page_title: "Admin Login",
          error_message: "Invalid email or password"
        )
    end
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:super_admin_id)
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: ~p"/admin/login")
  end
end
