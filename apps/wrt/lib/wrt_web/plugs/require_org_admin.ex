defmodule WrtWeb.Plugs.RequireOrgAdmin do
  @moduledoc """
  Plug that ensures the current user is an authenticated org admin.

  Requires TenantPlug to have run first to set :tenant in assigns.
  If no org admin is logged in, redirects to the org login page.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Wrt.Orgs

  def init(opts), do: opts

  def call(conn, _opts) do
    tenant = conn.assigns[:tenant]
    org_slug = conn.assigns[:current_org].slug

    with admin_id when not is_nil(admin_id) <- get_session(conn, :org_admin_id),
         %{} = admin <- Orgs.get_org_admin(tenant, admin_id) do
      conn
      |> assign(:current_org_admin, admin)
    else
      _ ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/org/#{org_slug}/login")
        |> halt()
    end
  end
end
