defmodule Portal.Audit do
  @moduledoc """
  Context for audit logging admin actions.

  Provides append-only logging of significant admin operations
  such as tool toggles, user management, and data exports.
  """

  import Ecto.Query
  alias Portal.Repo
  alias Portal.Audit.AuditLog

  @doc """
  Logs an audit event.

  ## Parameters

    * `actor` - The user performing the action (must have `id` and `email`)
    * `action` - String like "tool.toggle", "user.create", etc.
    * `entity_type` - String like "tool", "user", "signup_export"
    * `entity_id` - String ID of the affected entity (or nil)
    * `opts` - Keyword list with optional `:changes` map and `:ip_address` string

  """
  def log(actor, action, entity_type, entity_id, opts \\ []) do
    %AuditLog{}
    |> AuditLog.changeset(%{
      actor_id: actor.id,
      actor_email: actor.email,
      action: action,
      entity_type: entity_type,
      entity_id: if(entity_id, do: to_string(entity_id)),
      changes: Keyword.get(opts, :changes, %{}),
      ip_address: Keyword.get(opts, :ip_address)
    })
    |> Repo.insert()
  end

  @doc """
  Lists recent audit log entries, most recent first.
  """
  def list_recent(limit \\ 50) do
    from(a in AuditLog,
      order_by: [desc: a.inserted_at],
      limit: ^limit,
      preload: [:actor]
    )
    |> Repo.all()
  end

  @doc """
  Lists audit log entries for a specific entity.
  """
  def list_for_entity(entity_type, entity_id, limit \\ 50) do
    from(a in AuditLog,
      where: a.entity_type == ^entity_type and a.entity_id == ^to_string(entity_id),
      order_by: [desc: a.inserted_at],
      limit: ^limit,
      preload: [:actor]
    )
    |> Repo.all()
  end
end
