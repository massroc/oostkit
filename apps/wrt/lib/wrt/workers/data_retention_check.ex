defmodule Wrt.Workers.DataRetentionCheck do
  @moduledoc """
  Oban worker for checking and enforcing data retention policies.

  - Identifies campaigns that are past retention period
  - Sends warnings before deletion
  - Archives or deletes old campaign data
  """

  use Oban.Worker, queue: :maintenance, max_attempts: 3

  alias Wrt.Platform
  alias Wrt.Campaigns

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    retention_months = get_retention_months()
    warning_days = get_warning_days()

    action = args["action"] || "check"

    case action do
      "check" -> check_retention(retention_months, warning_days)
      "warn" -> send_warnings(args["org_id"], args["campaign_ids"])
      "archive" -> archive_campaigns(args["tenant"], args["campaign_ids"])
      _ -> {:error, :unknown_action}
    end
  end

  defp check_retention(retention_months, warning_days) do
    cutoff_date = months_ago(retention_months)
    # Warning date is retention period minus warning days
    warning_cutoff =
      months_ago(retention_months) |> DateTime.add(warning_days * 24 * 60 * 60, :second)

    orgs = Platform.list_organisations()

    Enum.each(orgs, fn org ->
      tenant = Platform.tenant_for_org(org)
      campaigns = Campaigns.list_campaigns(tenant)

      # Find campaigns that need warnings (between warning cutoff and actual cutoff)
      warning_campaigns =
        campaigns
        |> Enum.filter(fn c ->
          c.status == "completed" and
            DateTime.compare(c.updated_at, warning_cutoff) == :lt and
            DateTime.compare(c.updated_at, cutoff_date) == :gt
        end)

      # Find campaigns that need archival
      archive_campaigns =
        campaigns
        |> Enum.filter(fn c ->
          c.status == "completed" and
            DateTime.compare(c.updated_at, cutoff_date) == :lt
        end)

      if length(warning_campaigns) > 0 do
        Logger.info(
          "Queueing retention warnings for #{length(warning_campaigns)} campaigns in org #{org.id}"
        )

        queue_warnings(org.id, Enum.map(warning_campaigns, & &1.id))
      end

      if length(archive_campaigns) > 0 do
        Logger.info(
          "Queueing archival for #{length(archive_campaigns)} campaigns in org #{org.id}"
        )

        queue_archival(tenant, Enum.map(archive_campaigns, & &1.id))
      end
    end)

    :ok
  end

  defp send_warnings(org_id, campaign_ids) do
    org = Platform.get_organisation(org_id)

    if org do
      # TODO: Send email to org admins about upcoming data deletion
      Logger.info(
        "Would send retention warning to org #{org_id} for campaigns: #{inspect(campaign_ids)}"
      )
    end

    :ok
  end

  defp archive_campaigns(tenant, campaign_ids) do
    Enum.each(campaign_ids, fn campaign_id ->
      case Campaigns.get_campaign(tenant, campaign_id) do
        nil ->
          Logger.warning("Campaign #{campaign_id} not found for archival")

        campaign ->
          # For now, we just log. In production, you might:
          # 1. Export data to cold storage
          # 2. Delete the campaign and related data
          # 3. Update campaign status to "archived"
          Logger.info("Would archive campaign #{campaign.id}: #{campaign.name}")
      end
    end)

    :ok
  end

  defp queue_warnings(org_id, campaign_ids) do
    %{action: "warn", org_id: org_id, campaign_ids: campaign_ids}
    |> new()
    |> Oban.insert()
  end

  defp queue_archival(tenant, campaign_ids) do
    %{action: "archive", tenant: tenant, campaign_ids: campaign_ids}
    |> new()
    |> Oban.insert()
  end

  defp get_retention_months do
    Application.get_env(:wrt, :data_retention, [])
    |> Keyword.get(:campaign_retention_months, 24)
  end

  defp get_warning_days do
    Application.get_env(:wrt, :data_retention, [])
    |> Keyword.get(:warning_days_before_deletion, 30)
  end

  defp months_ago(months) do
    DateTime.utc_now()
    |> DateTime.add(-months * 30 * 24 * 60 * 60, :second)
  end

  @doc """
  Schedules the retention check to run weekly.
  """
  def schedule do
    %{action: "check"}
    |> new(schedule_in: 7 * 24 * 60 * 60)
    |> Oban.insert()
  end
end
