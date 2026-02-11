defmodule Portal.Repo.Migrations.CreateInterestSignups do
  use Ecto.Migration

  def change do
    create table(:interest_signups) do
      add :name, :string
      add :email, :string, null: false
      add :context, :string

      timestamps(updated_at: false)
    end

    create unique_index(:interest_signups, [:email])
  end
end
