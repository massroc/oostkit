defmodule Wrt.Repo.TenantMigrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :string, null: false
      add :email, :citext, null: false
      add :source, :string, null: false, default: "nominated"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:people, [:email])
    create index(:people, [:source])
  end
end
