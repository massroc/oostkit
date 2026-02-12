defmodule Portal.Repo.Migrations.AddProductUpdatesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :product_updates, :boolean, null: false, default: false
    end
  end
end
