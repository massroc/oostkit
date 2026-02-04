defmodule Wrt.People.Person do
  @moduledoc """
  Schema for people in the referral system.

  A person can be either:
  - seed: Added as part of the initial seed group
  - nominated: Added through the nomination process
  """

  use Ecto.Schema
  import Ecto.Changeset

  @sources ~w(seed nominated)

  schema "people" do
    field :name, :string
    field :email, :string
    field :source, :string, default: "nominated"

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a person.
  """
  def changeset(person, attrs) do
    person
    |> cast(attrs, [:name, :email, :source])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:name, min: 1, max: 255)
    |> validate_inclusion(:source, @sources)
    |> unique_constraint(:email)
    |> downcase_email()
  end

  @doc """
  Changeset for creating a seed person.
  """
  def seed_changeset(person, attrs) do
    person
    |> changeset(attrs)
    |> put_change(:source, "seed")
  end

  @doc """
  Changeset for creating a nominated person.
  """
  def nominated_changeset(person, attrs) do
    person
    |> changeset(attrs)
    |> put_change(:source, "nominated")
  end

  @doc """
  Returns valid source values.
  """
  def sources, do: @sources

  @doc """
  Checks if the person is from the seed group.
  """
  def seed?(%__MODULE__{source: "seed"}), do: true
  def seed?(_), do: false

  @doc """
  Checks if the person was nominated.
  """
  def nominated?(%__MODULE__{source: "nominated"}), do: true
  def nominated?(_), do: false

  defp downcase_email(changeset) do
    case get_change(changeset, :email) do
      nil -> changeset
      email -> put_change(changeset, :email, String.downcase(email))
    end
  end
end
