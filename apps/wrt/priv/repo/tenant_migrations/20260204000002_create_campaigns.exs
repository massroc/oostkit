defmodule Wrt.Repo.TenantMigrations.CreateCampaigns do
  use Ecto.Migration

  def change do
    create table(:campaigns) do
      add :name, :string, null: false
      add :description, :text
      add :status, :string, null: false, default: "draft"
      add :default_round_duration_days, :integer, default: 7
      add :target_participant_count, :integer

      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:campaigns, [:status])
  end
end
