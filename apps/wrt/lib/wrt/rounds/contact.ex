defmodule Wrt.Rounds.Contact do
  @moduledoc """
  Schema for tracking contact with people during rounds.

  A contact records when a person was invited to participate in a round
  and tracks their response status.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Wrt.People.Person
  alias Wrt.Rounds.Round

  @email_statuses ~w(pending sent delivered opened clicked bounced spam)

  schema "contacts" do
    field :email_status, :string, default: "pending"

    field :invited_at, :utc_datetime
    field :delivered_at, :utc_datetime
    field :opened_at, :utc_datetime
    field :clicked_at, :utc_datetime
    field :responded_at, :utc_datetime

    belongs_to :person, Person
    belongs_to :round, Round

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a contact.
  """
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:person_id, :round_id])
    |> validate_required([:person_id, :round_id])
    |> foreign_key_constraint(:person_id)
    |> foreign_key_constraint(:round_id)
    |> unique_constraint([:person_id, :round_id])
  end

  @doc """
  Changeset for marking as invited (email sent).
  """
  def invite_changeset(contact) do
    contact
    |> change()
    |> put_change(:email_status, "sent")
    |> put_change(:invited_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset for updating email status.
  """
  def email_status_changeset(contact, status, timestamp_field) do
    contact
    |> change()
    |> put_change(:email_status, status)
    |> put_change(timestamp_field, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset for marking as responded.
  """
  def respond_changeset(contact) do
    contact
    |> change()
    |> put_change(:responded_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Returns valid email status values.
  """
  def email_statuses, do: @email_statuses

  @doc """
  Checks if the contact has responded.
  """
  def responded?(%__MODULE__{responded_at: nil}), do: false
  def responded?(%__MODULE__{}), do: true
end
