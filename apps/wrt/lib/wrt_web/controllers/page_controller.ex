defmodule WrtWeb.PageController do
  use WrtWeb, :controller

  alias Wrt.Platform
  alias Wrt.Platform.Organisation

  def home(conn, _params) do
    email = conn.assigns.portal_user["email"]

    case Platform.get_organisation_by_admin_email(email) do
      nil ->
        render(conn, :no_org, page_title: "No Organisation Found")

      %Organisation{} = org ->
        if Organisation.active?(org) do
          if skip_landing?(conn) do
            redirect(conn, to: ~p"/org/#{org.slug}/manage")
          else
            render(conn, :landing, page_title: "Workshop Referral Tool", org: org)
          end
        else
          render(conn, :inactive,
            page_title: "Organisation Inactive",
            org: org
          )
        end
    end
  end

  def dismiss_landing(conn, params) do
    email = conn.assigns.portal_user["email"]
    org = Platform.get_organisation_by_admin_email(email)

    conn =
      if params["skip"] == "true" do
        put_resp_cookie(conn, "wrt_skip_landing", "1", max_age: 365 * 24 * 60 * 60)
      else
        conn
      end

    redirect(conn, to: ~p"/org/#{org.slug}/manage")
  end

  defp skip_landing?(conn) do
    conn = fetch_cookies(conn)
    conn.cookies["wrt_skip_landing"] == "1"
  end
end
