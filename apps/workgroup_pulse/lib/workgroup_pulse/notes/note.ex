defmodule WorkgroupPulse.Notes.Note do
  @moduledoc """
  Schema for discussion notes.

  Notes capture discussion points and observations during the workshop.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias WorkgroupPulse.Sessions.Session

  schema "notes" do
    field :content, :string

    belongs_to :session, Session

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:content])
    |> validate_required([:content])
    |> validate_length(:content, min: 1, max: 2000)
  end

  @doc """
  Changeset for creating a note.
  """
  def create_changeset(note, session, attrs) do
    note
    |> changeset(attrs)
    |> put_assoc(:session, session)
  end
end
