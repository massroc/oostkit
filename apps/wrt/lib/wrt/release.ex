defmodule Wrt.Release do
  @moduledoc """
  Release tasks for database migrations and seeding.

  Used by the release command in fly.toml to run migrations on deployment.
  Handles both main schema migrations and tenant schema migrations.
  """

  @app :wrt

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    # Migrate all tenant schemas
    migrate_tenants()
  end

  def migrate_tenants do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(Wrt.Repo, fn _repo ->
        Wrt.TenantManager.migrate_all_tenants()
      end)
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, fn _repo -> run_seeds() end)
    end
  end

  defp run_seeds do
    seed_script = Application.app_dir(@app, "priv/repo/seeds.exs")

    if File.exists?(seed_script) do
      Code.eval_file(seed_script)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
