defmodule WrtWeb.Plugs.FetchCurrentOrgAdmin do
  @moduledoc """
  Plug that fetches the current org admin from the session (if any).

  Requires TenantPlug to have run first to set :tenant in assigns.
  Unlike RequireOrgAdmin, this plug does not require authentication.
  """

  import Plug.Conn

  alias Wrt.Orgs

  def init(opts), do: opts

  def call(conn, _opts) do
    tenant = conn.assigns[:tenant]
    admin_id = get_session(conn, :org_admin_id)

    if tenant && admin_id do
      case Orgs.get_org_admin(tenant, admin_id) do
        nil ->
          conn
          |> delete_session(:org_admin_id)
          |> assign(:current_org_admin, nil)

        admin ->
          assign(conn, :current_org_admin, admin)
      end
    else
      assign(conn, :current_org_admin, nil)
    end
  end
end
