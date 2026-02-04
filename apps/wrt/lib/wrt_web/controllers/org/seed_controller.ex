defmodule WrtWeb.Org.SeedController do
  use WrtWeb, :controller

  alias Wrt.Campaigns
  alias Wrt.People

  plug WrtWeb.Plugs.TenantPlug
  plug WrtWeb.Plugs.RequireOrgAdmin

  def index(conn, %{"campaign_id" => campaign_id}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)
    seed_people = People.list_seed_people(tenant)

    render(conn, :index,
      page_title: "Seed Group",
      org: org,
      campaign: campaign,
      seed_people: seed_people
    )
  end

  def upload(conn, %{"campaign_id" => campaign_id, "csv" => %Plug.Upload{} = upload}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)

    case File.read(upload.path) do
      {:ok, content} ->
        case People.parse_seed_csv(content) do
          {:ok, parsed_people} ->
            {:ok, results} = People.import_seed_people(tenant, parsed_people)

            message =
              "Imported #{results.imported} people." <>
                if(results.skipped > 0, do: " Skipped #{results.skipped} duplicates.", else: "") <>
                if(length(results.errors) > 0,
                  do: " #{length(results.errors)} errors.",
                  else: ""
                )

            conn
            |> put_flash(:info, message)
            |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/seed")

          {:error, reason} ->
            conn
            |> put_flash(:error, "Failed to parse CSV: #{reason}")
            |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/seed")
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to read uploaded file.")
        |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/seed")
    end
  end

  def upload(conn, %{"campaign_id" => campaign_id}) do
    org = conn.assigns.current_org

    conn
    |> put_flash(:error, "Please select a CSV file to upload.")
    |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign_id}/seed")
  end

  def add(conn, %{"campaign_id" => campaign_id, "person" => person_params}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)

    case People.create_seed_person(tenant, person_params) do
      {:ok, _person} ->
        conn
        |> put_flash(:info, "Person added to seed group.")
        |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/seed")

      {:error, changeset} ->
        seed_people = People.list_seed_people(tenant)

        render(conn, :index,
          page_title: "Seed Group",
          org: org,
          campaign: campaign,
          seed_people: seed_people,
          changeset: changeset
        )
    end
  end
end
