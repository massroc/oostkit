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

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        changeset
        |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end

  @doc """
  Verifies a password against the stored hash.
  """
  def valid_password?(%__MODULE__{password_hash: hash}, password)
      when is_binary(hash) and is_binary(password) do
    Bcrypt.verify_pass(password, hash)
  end

  def valid_password?(_, _), do: false
end
