defmodule Wrt.Repo.TenantMigrations.CreateNominations do
  use Ecto.Migration

  def change do
    create table(:nominations) do
      add :round_id, references(:rounds, on_delete: :delete_all), null: false
      add :nominator_id, references(:people, on_delete: :delete_all), null: false
      add :nominee_id, references(:people, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:nominations, [:round_id])
    create index(:nominations, [:nominator_id])
    create index(:nominations, [:nominee_id])
    # Prevent duplicate nominations (same person nominating same person in same round)
    create unique_index(:nominations, [:round_id, :nominator_id, :nominee_id])
  end
end
