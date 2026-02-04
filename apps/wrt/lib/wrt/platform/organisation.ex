defmodule Wrt.Platform.Organisation do
  @moduledoc """
  Schema for organisations (tenants).

  Each organisation has its own isolated database schema.
  Organisations go through an approval workflow before becoming active.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Wrt.Platform.SuperAdmin

  @statuses ~w(pending approved rejected suspended)

  schema "organisations" do
    field :name, :string
    field :slug, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :admin_name, :string
    field :admin_email, :string

    field :approved_at, :utc_datetime
    belongs_to :approved_by, SuperAdmin
    field :rejection_reason, :string

    field :suspended_at, :utc_datetime
    belongs_to :suspended_by, SuperAdmin
    field :suspension_reason, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for organisation registration.
  """
  def registration_changeset(organisation, attrs) do
    organisation
    |> cast(attrs, [:name, :description, :admin_name, :admin_email])
    |> validate_required([:name, :admin_name, :admin_email])
    |> validate_format(:admin_email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/,
      message: "must be a valid email"
    )
    |> generate_slug()
    |> unique_constraint(:slug)
    |> unique_constraint(:admin_email)
  end

  @doc """
  Changeset for approving an organisation.
  """
  def approve_changeset(organisation, super_admin) do
    organisation
    |> change()
    |> put_change(:status, "approved")
    |> put_change(:approved_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> put_change(:approved_by_id, super_admin.id)
    |> put_change(:rejection_reason, nil)
  end

  @doc """
  Changeset for rejecting an organisation.
  """
  def reject_changeset(organisation, reason) do
    organisation
    |> change()
    |> put_change(:status, "rejected")
    |> put_change(:rejection_reason, reason)
  end

  @doc """
  Changeset for suspending an organisation.
  """
  def suspend_changeset(organisation, super_admin, reason) do
    organisation
    |> change()
    |> put_change(:status, "suspended")
    |> put_change(:suspended_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> put_change(:suspended_by_id, super_admin.id)
    |> put_change(:suspension_reason, reason)
  end

  @doc """
  Changeset for reactivating a suspended organisation.
  """
  def reactivate_changeset(organisation) do
    organisation
    |> change()
    |> put_change(:status, "approved")
    |> put_change(:suspended_at, nil)
    |> put_change(:suspended_by_id, nil)
    |> put_change(:suspension_reason, nil)
  end

  @doc """
  Returns valid status values.
  """
  def statuses, do: @statuses

  @doc """
  Checks if the organisation is approved and active.
  """
  def active?(%__MODULE__{status: "approved"}), do: true
  def active?(_), do: false

  @doc """
  Checks if the organisation is pending approval.
  """
  def pending?(%__MODULE__{status: "pending"}), do: true
  def pending?(_), do: false

  @doc """
  Checks if the organisation is suspended.
  """
  def suspended?(%__MODULE__{status: "suspended"}), do: true
  def suspended?(_), do: false

  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        slug =
          name
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9\s-]/, "")
          |> String.replace(~r/\s+/, "-")
          |> String.trim("-")

        put_change(changeset, :slug, slug)
    end
  end
end
