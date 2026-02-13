defmodule Portal.Audit.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    belongs_to :actor, Portal.Accounts.User
    field :actor_email, :string
    field :action, :string
    field :entity_type, :string
    field :entity_id, :string
    field :changes, :map, default: %{}
    field :ip_address, :string

    timestamps(updated_at: false)
  end

  @required_fields ~w(actor_email action entity_type)a
  @optional_fields ~w(actor_id entity_id changes ip_address)a

  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
