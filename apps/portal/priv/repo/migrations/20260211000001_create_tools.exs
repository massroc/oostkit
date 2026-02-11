defmodule Portal.Repo.Migrations.CreateTools do
  use Ecto.Migration

  def change do
    create table(:tools, primary_key: false) do
      add :id, :string, primary_key: true
      add :name, :string, null: false
      add :tagline, :string, null: false
      add :description, :text
      add :url, :string
      add :audience, :string, null: false
      add :default_status, :string, null: false, default: "coming_soon"
      add :admin_enabled, :boolean, null: false, default: true
      add :sort_order, :integer, null: false, default: 0

      timestamps()
    end

    create unique_index(:tools, [:sort_order])
  end
end
