defmodule WorkgroupPulse.Repo.Migrations.SimplifyNotesAndActions do
  use Ecto.Migration

  def change do
    alter table(:notes) do
      remove :question_index, :integer
      remove :author_name, :string
    end

    alter table(:actions) do
      remove :owner_name, :string
    end
  end
end
