defmodule WrtWeb.Plugs.TenantPlug do
  @moduledoc """
  Plug that extracts the tenant from the URL path.

  Looks for the org_slug path parameter and loads the corresponding organisation.
  Sets :current_org and :tenant in conn.assigns.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Wrt.Platform

  def init(opts), do: opts

  alias Wrt.Platform.Organisation

  def call(conn, _opts) do
    case conn.path_params["org_slug"] do
      nil -> conn
      slug -> load_organisation(conn, slug)
    end
  end

  defp load_organisation(conn, slug) do
    case Platform.get_organisation_by_slug(slug) do
      nil -> render_not_found(conn)
      org -> assign_org_if_active(conn, org)
    end
  end

  defp render_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(html: WrtWeb.ErrorHTML)
    |> render("404.html")
    |> halt()
  end

  defp assign_org_if_active(conn, org) do
    if Organisation.active?(org) do
      tenant = Platform.tenant_for_org(org)

      conn
      |> assign(:current_org, org)
      |> assign(:tenant, tenant)
    else
      conn
      |> put_flash(:error, "This organisation is not active.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
