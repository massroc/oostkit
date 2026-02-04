defmodule Wrt.Repo.TenantMigrations.CreateOrgAdmins do
  use Ecto.Migration

  def change do
    create table(:org_admins) do
      add :name, :string, null: false
      add :email, :citext, null: false
      add :password_hash, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:org_admins, [:email])
  end
end
