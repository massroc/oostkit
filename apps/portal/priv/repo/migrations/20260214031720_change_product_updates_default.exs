defmodule Portal.Repo.Migrations.ChangeProductUpdatesDefault do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :product_updates, :boolean, null: false, default: true
    end
  end
end
