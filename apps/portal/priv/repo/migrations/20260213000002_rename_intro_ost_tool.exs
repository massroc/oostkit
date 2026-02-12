defmodule Portal.Repo.Migrations.RenameIntroOstTool do
  use Ecto.Migration

  def up do
    execute "UPDATE tools SET name = 'Introduction to OST' WHERE id = 'intro_ost'"
  end

  def down do
    execute "UPDATE tools SET name = 'Introduction to Open Systems Thinking' WHERE id = 'intro_ost'"
  end
end
