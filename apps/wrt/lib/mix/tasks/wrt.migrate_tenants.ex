defmodule Mix.Tasks.Wrt.MigrateTenants do
  @moduledoc """
  Runs tenant migrations for all existing tenant schemas.

  ## Usage

      mix wrt.migrate_tenants

  This task finds all schemas prefixed with "tenant_" and runs
  the migrations from priv/repo/tenant_migrations against each one.
  """

  use Mix.Task

  @shortdoc "Runs migrations for all tenant schemas"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    tenants = Wrt.TenantManager.list_tenants()

    case tenants do
      [] ->
        Mix.shell().info("No tenant schemas found.")

      _ ->
        Mix.shell().info("Found #{Enum.count(tenants)} tenant schema(s)")
        Enum.each(tenants, &migrate_single_tenant/1)
        Mix.shell().info("Done.")
    end
  end

  defp migrate_single_tenant(schema) do
    Mix.shell().info("Migrating #{schema}...")

    case Wrt.TenantManager.migrate_tenant(schema) do
      {:ok, _} -> Mix.shell().info("  ✓ #{schema} migrated successfully")
      {:error, reason} -> Mix.shell().error("  ✗ #{schema} failed: #{inspect(reason)}")
    end
  end
end
