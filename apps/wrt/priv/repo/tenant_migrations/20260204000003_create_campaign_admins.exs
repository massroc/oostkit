defmodule Wrt.Repo.TenantMigrations.CreateCampaignAdmins do
  use Ecto.Migration

  def change do
    create table(:campaign_admins) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :email, :citext, null: false
      add :password_hash, :string, null: false
      add :invited_by_id, references(:org_admins, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:campaign_admins, [:campaign_id])
    create unique_index(:campaign_admins, [:campaign_id, :email])
  end
end
