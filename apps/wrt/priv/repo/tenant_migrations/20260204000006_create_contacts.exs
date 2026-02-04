defmodule Wrt.Repo.TenantMigrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :person_id, references(:people, on_delete: :delete_all), null: false
      add :round_id, references(:rounds, on_delete: :delete_all), null: false
      add :email_status, :string, null: false, default: "pending"

      add :invited_at, :utc_datetime
      add :delivered_at, :utc_datetime
      add :opened_at, :utc_datetime
      add :clicked_at, :utc_datetime
      add :responded_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:contacts, [:person_id])
    create index(:contacts, [:round_id])
    create unique_index(:contacts, [:person_id, :round_id])
    create index(:contacts, [:email_status])
  end
end
