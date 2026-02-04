defmodule Wrt.Repo.Migrations.CreateOrganisations do
  use Ecto.Migration

  def change do
    create table(:organisations) do
      add :name, :string, null: false
      add :slug, :citext, null: false
      add :description, :text
      add :status, :string, null: false, default: "pending"
      add :admin_name, :string, null: false
      add :admin_email, :citext, null: false

      add :approved_at, :utc_datetime
      add :approved_by_id, references(:super_admins, on_delete: :nilify_all)
      add :rejection_reason, :text
      add :suspended_at, :utc_datetime
      add :suspended_by_id, references(:super_admins, on_delete: :nilify_all)
      add :suspension_reason, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organisations, [:slug])
    create unique_index(:organisations, [:admin_email])
    create index(:organisations, [:status])
  end
end
