defmodule Wrt.Auth.Password do
  @moduledoc """
  Shared password hashing and verification for admin schemas.
  """

  import Ecto.Changeset

  def hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        changeset
        |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end

  def valid_password?(%{password_hash: hash}, password)
      when is_binary(hash) and is_binary(password) do
    Bcrypt.verify_pass(password, hash)
  end

  def valid_password?(_, _), do: false
end
