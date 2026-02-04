defmodule Wrt.Workers.CleanupExpiredMagicLinks do
  @moduledoc """
  Oban worker for cleaning up expired magic links.

  Runs periodically to remove magic links that have expired,
  freeing up database space and maintaining data hygiene.
  """

  use Oban.Worker, queue: :maintenance, max_attempts: 3

  alias Wrt.MagicLinks
  alias Wrt.TenantManager

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    tenants = TenantManager.list_tenants()

    total_deleted =
      Enum.reduce(tenants, 0, fn tenant, acc ->
        deleted = MagicLinks.delete_expired(tenant)
        acc + deleted
      end)

    if total_deleted > 0 do
      Logger.info(
        "Cleaned up #{total_deleted} expired magic links across #{Enum.count(tenants)} tenants"
      )
    end

    :ok
  end

  @doc """
  Schedules the cleanup job to run daily.

  Call this from your application startup or use Oban's cron plugin.
  """
  def schedule do
    %{}
    |> new(schedule_in: 24 * 60 * 60)
    |> Oban.insert()
  end
end
