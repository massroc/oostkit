defmodule Wrt.People.Nomination do
  @moduledoc """
  Schema for nominations.

  A nomination records one person nominating another in a specific round.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Wrt.People.Person
  alias Wrt.Rounds.Round

  schema "nominations" do
    belongs_to :round, Round
    belongs_to :nominator, Person
    belongs_to :nominee, Person

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a nomination.
  """
  def changeset(nomination, attrs) do
    nomination
    |> cast(attrs, [:round_id, :nominator_id, :nominee_id])
    |> validate_required([:round_id, :nominator_id, :nominee_id])
    |> foreign_key_constraint(:round_id)
    |> foreign_key_constraint(:nominator_id)
    |> foreign_key_constraint(:nominee_id)
    |> unique_constraint([:round_id, :nominator_id, :nominee_id],
      message: "this person has already been nominated by this nominator in this round"
    )
    |> validate_not_self_nomination()
  end

  defp validate_not_self_nomination(changeset) do
    nominator_id = get_field(changeset, :nominator_id)
    nominee_id = get_field(changeset, :nominee_id)

    if nominator_id && nominee_id && nominator_id == nominee_id do
      add_error(changeset, :nominee_id, "cannot nominate yourself")
    else
      changeset
    end
  end
end
