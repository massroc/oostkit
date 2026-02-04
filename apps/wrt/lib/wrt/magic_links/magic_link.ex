defmodule Wrt.MagicLinks.MagicLink do
  @moduledoc """
  Schema for magic link tokens used by nominators.

  Magic links allow nominators to access the nomination form without a password.
  Each link is tied to a specific person and round, is single-use, and expires.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @token_bytes 32
  @code_length 6
  @token_validity_hours 24
  @code_validity_minutes 15

  schema "magic_links" do
    field :token, :string
    field :code, :string
    field :code_expires_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :used_at, :utc_datetime

    belongs_to :person, Wrt.People.Person
    belongs_to :round, Wrt.Rounds.Round

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a new magic link.
  """
  def changeset(magic_link, attrs) do
    magic_link
    |> cast(attrs, [:person_id, :round_id])
    |> validate_required([:person_id, :round_id])
    |> generate_token()
    |> set_expiration()
    |> foreign_key_constraint(:person_id)
    |> foreign_key_constraint(:round_id)
    |> unique_constraint(:token)
  end

  @doc """
  Creates a changeset for generating a verification code.
  """
  def code_changeset(magic_link) do
    magic_link
    |> change()
    |> generate_code()
    |> set_code_expiration()
  end

  @doc """
  Creates a changeset for marking the link as used.
  """
  def use_changeset(magic_link) do
    magic_link
    |> change()
    |> put_change(:used_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Checks if the magic link has expired.
  """
  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  @doc """
  Checks if the magic link has been used.
  """
  def used?(%__MODULE__{used_at: used_at}) do
    not is_nil(used_at)
  end

  @doc """
  Checks if the verification code has expired.
  """
  def code_expired?(%__MODULE__{code_expires_at: nil}), do: true

  def code_expired?(%__MODULE__{code_expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  @doc """
  Checks if the magic link is valid (not expired and not used).
  """
  def valid?(%__MODULE__{} = magic_link) do
    not expired?(magic_link) and not used?(magic_link)
  end

  # Private functions

  defp generate_token(changeset) do
    token =
      :crypto.strong_rand_bytes(@token_bytes)
      |> Base.url_encode64(padding: false)

    put_change(changeset, :token, token)
  end

  defp generate_code(changeset) do
    code =
      :crypto.strong_rand_bytes(4)
      |> :binary.decode_unsigned()
      |> rem(1_000_000)
      |> Integer.to_string()
      |> String.pad_leading(@code_length, "0")

    put_change(changeset, :code, code)
  end

  defp set_expiration(changeset) do
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(@token_validity_hours * 60 * 60, :second)
      |> DateTime.truncate(:second)

    put_change(changeset, :expires_at, expires_at)
  end

  defp set_code_expiration(changeset) do
    expires_at =
      DateTime.utc_now()
      |> DateTime.add(@code_validity_minutes * 60, :second)
      |> DateTime.truncate(:second)

    put_change(changeset, :code_expires_at, expires_at)
  end
end
