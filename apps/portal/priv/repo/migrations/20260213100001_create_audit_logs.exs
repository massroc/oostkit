defmodule Portal.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :actor_id, references(:users, on_delete: :nilify_all)
      add :actor_email, :string, null: false
      add :action, :string, null: false
      add :entity_type, :string, null: false
      add :entity_id, :string
      add :changes, :map, default: %{}
      add :ip_address, :string

      timestamps(updated_at: false)
    end

    create index(:audit_logs, [:actor_id])
    create index(:audit_logs, [:entity_type, :entity_id])
    create index(:audit_logs, [:inserted_at])
  end
end
