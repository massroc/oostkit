defmodule Wrt.Repo.TenantMigrations.CreateRounds do
  use Ecto.Migration

  def change do
    create table(:rounds) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :round_number, :integer, null: false
      add :status, :string, null: false, default: "pending"
      add :deadline, :utc_datetime
      add :reminder_enabled, :boolean, default: false
      add :reminder_days, :integer, default: 2

      add :started_at, :utc_datetime
      add :closed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:rounds, [:campaign_id])
    create unique_index(:rounds, [:campaign_id, :round_number])
  end
end
