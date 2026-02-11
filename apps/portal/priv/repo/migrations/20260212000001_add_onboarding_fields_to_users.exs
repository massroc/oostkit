defmodule Portal.Repo.Migrations.AddOnboardingFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :organisation, :string
      add :referral_source, :string
      add :onboarding_completed, :boolean, null: false, default: false
    end

    create table(:user_tool_interests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :tool_id, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:user_tool_interests, [:user_id])
    create unique_index(:user_tool_interests, [:user_id, :tool_id])
  end
end
