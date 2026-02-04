defmodule Wrt.Repo.TenantMigrations.CreateMagicLinks do
  use Ecto.Migration

  def change do
    create table(:magic_links) do
      add :person_id, references(:people, on_delete: :delete_all), null: false
      add :round_id, references(:rounds, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :code, :string
      add :code_expires_at, :utc_datetime
      add :expires_at, :utc_datetime, null: false
      add :used_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:magic_links, [:token])
    create index(:magic_links, [:person_id])
    create index(:magic_links, [:round_id])
  end
end
