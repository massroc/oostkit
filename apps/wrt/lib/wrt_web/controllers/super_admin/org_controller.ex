defmodule WrtWeb.SuperAdmin.OrgController do
  use WrtWeb, :controller

  alias Wrt.Platform

  plug :put_layout, html: {WrtWeb.Layouts, :admin}

  def index(conn, params) do
    status_filter = params["status"]

    organisations =
      if status_filter && status_filter in ~w(pending approved rejected suspended) do
        Platform.list_organisations_by_status(status_filter)
      else
        Platform.list_organisations()
      end

    render(conn, :index,
      page_title: "Organisations",
      organisations: organisations,
      status_filter: status_filter
    )
  end

  def show(conn, %{"id" => id}) do
    org = Platform.get_organisation!(id)

    render(conn, :show,
      page_title: org.name,
      organisation: org
    )
  end

  def approve(conn, %{"id" => id}) do
    org = Platform.get_organisation!(id)
    super_admin = Platform.get_super_admin_by_email(conn.assigns.portal_user["email"])

    case Platform.approve_organisation(org, super_admin) do
      {:ok, _org} ->
        conn
        |> put_flash(:info, "Organisation approved and tenant created.")
        |> redirect(to: ~p"/admin/orgs")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to approve organisation: #{inspect(reason)}")
        |> redirect(to: ~p"/admin/orgs/#{id}")
    end
  end

  def reject(conn, %{"id" => id} = params) do
    org = Platform.get_organisation!(id)
    reason = params["reason"]

    case Platform.reject_organisation(org, reason) do
      {:ok, _org} ->
        conn
        |> put_flash(:info, "Organisation registration rejected.")
        |> redirect(to: ~p"/admin/orgs")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to reject organisation.")
        |> redirect(to: ~p"/admin/orgs/#{id}")
    end
  end

  def suspend(conn, %{"id" => id} = params) do
    org = Platform.get_organisation!(id)
    reason = params["reason"]

    super_admin = Platform.get_super_admin_by_email(conn.assigns.portal_user["email"])

    case Platform.suspend_organisation(org, super_admin, reason) do
      {:ok, _org} ->
        conn
        |> put_flash(:info, "Organisation suspended.")
        |> redirect(to: ~p"/admin/orgs")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to suspend organisation.")
        |> redirect(to: ~p"/admin/orgs/#{id}")
    end
  end
end
