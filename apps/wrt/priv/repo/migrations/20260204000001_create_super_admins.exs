defmodule Wrt.Repo.Migrations.CreateSuperAdmins do
  use Ecto.Migration

  def change do
    create table(:super_admins) do
      add :name, :string, null: false
      add :email, :citext, null: false
      add :password_hash, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:super_admins, [:email])
  end
end
