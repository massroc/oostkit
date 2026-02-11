defmodule WrtWeb.Org.RoundController do
  use WrtWeb, :controller

  alias Wrt.Campaigns
  alias Wrt.People
  alias Wrt.Rounds

  plug WrtWeb.Plugs.TenantPlug

  def index(conn, %{"campaign_id" => campaign_id}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)
    rounds = Rounds.list_rounds(tenant, campaign.id)
    active_round = Rounds.get_active_round(tenant, campaign.id)
    can_start_round = active_round == nil

    render(conn, :index,
      page_title: "Rounds",
      org: org,
      campaign: campaign,
      rounds: rounds,
      active_round: active_round,
      can_start_round: can_start_round
    )
  end

  def create(conn, %{"campaign_id" => campaign_id, "round" => round_params}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)

    # Check if there's already an active round
    if Rounds.get_active_round(tenant, campaign.id) do
      conn
      |> put_flash(
        :error,
        "There is already an active round. Close it before starting a new one."
      )
      |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/rounds")
    else
      do_create_round(conn, tenant, org, campaign, round_params)
    end
  end

  defp do_create_round(conn, tenant, org, campaign, round_params) do
    duration_days = String.to_integer(round_params["duration_days"] || "7")

    case Rounds.create_round(tenant, campaign.id) do
      {:ok, round} ->
        maybe_start_campaign(tenant, campaign, round)
        start_round_and_redirect(conn, tenant, org, campaign, round, duration_days)

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to create round.")
        |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/rounds")
    end
  end

  defp maybe_start_campaign(tenant, campaign, round) do
    if round.round_number == 1 and campaign.status == "draft" do
      Campaigns.start_campaign(tenant, campaign)
    end
  end

  defp start_round_and_redirect(conn, tenant, org, campaign, round, duration_days) do
    case Rounds.start_round(tenant, round, duration_days) do
      {:ok, {started_round, contacts}} ->
        conn
        |> put_flash(
          :info,
          "Round #{started_round.round_number} started with #{Enum.count(contacts)} contacts."
        )
        |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/rounds/#{started_round}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to start round: #{inspect(reason)}")
        |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/rounds")
    end
  end

  def show(conn, %{"campaign_id" => campaign_id, "id" => id}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)
    round = Rounds.get_round!(tenant, id)
    contacts = Rounds.list_contacts(tenant, round.id)
    contact_stats = Rounds.count_contacts(tenant, round.id)
    nominations = People.list_nominations_for_round(tenant, round.id)

    render(conn, :show,
      page_title: "Round #{round.round_number}",
      org: org,
      campaign: campaign,
      round: round,
      contacts: contacts,
      contact_stats: contact_stats,
      nominations: nominations
    )
  end

  def close(conn, %{"campaign_id" => campaign_id, "round_id" => round_id}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)
    round = Rounds.get_round!(tenant, round_id)

    case Rounds.close_round(tenant, round) do
      {:ok, _round} ->
        conn
        |> put_flash(:info, "Round #{round.round_number} has been closed.")
        |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/rounds")

      {:error, :round_not_active} ->
        conn
        |> put_flash(:error, "This round is not active.")
        |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/rounds/#{round}")
    end
  end

  def extend(conn, %{
        "campaign_id" => campaign_id,
        "round_id" => round_id,
        "extension" => extension_params
      }) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)
    round = Rounds.get_round!(tenant, round_id)

    days = String.to_integer(extension_params["days"] || "7")

    new_deadline =
      round.deadline
      |> DateTime.add(days * 24 * 60 * 60, :second)

    case Rounds.extend_round(tenant, round, new_deadline) do
      {:ok, _round} ->
        conn
        |> put_flash(:info, "Round deadline extended by #{days} days.")
        |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/rounds/#{round}")

      {:error, :round_not_active} ->
        conn
        |> put_flash(:error, "This round is not active.")
        |> redirect(to: ~p"/org/#{org.slug}/campaigns/#{campaign}/rounds/#{round}")
    end
  end
end
