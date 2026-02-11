defmodule Wrt.Platform.SuperAdmin do
  @moduledoc """
  Schema for platform super administrators.

  Super admins can:
  - Approve/reject organisation registration requests
  - Suspend organisations
  - View platform-wide metrics
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Wrt.Auth.Password

  schema "super_admins" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new super admin.
  """
  def changeset(super_admin, attrs) do
    super_admin
    |> cast(attrs, [:name, :email, :password])
    |> validate_required([:name, :email, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
    |> unique_constraint(:email)
    |> hash_password()
  end

  @doc """
  Changeset for updating super admin details (not password).
  """
  def update_changeset(super_admin, attrs) do
    super_admin
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:email)
  end

  @doc """
  Changeset for updating password.
  """
  def password_changeset(super_admin, attrs) do
    super_admin
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
    |> hash_password()
  end

  defdelegate valid_password?(admin, password), to: Wrt.Auth.Password
end
