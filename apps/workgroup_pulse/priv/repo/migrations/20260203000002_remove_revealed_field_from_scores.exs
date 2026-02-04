defmodule WorkgroupPulse.Repo.Migrations.RemoveRevealedFieldFromScores do
  use Ecto.Migration

  @moduledoc """
  Removes the revealed field from scores.

  This field was part of the original planning poker-style flow where
  scores were hidden until revealed. The simplified turn-based flow
  shows scores immediately when placed (butcher paper model), making
  this field obsolete.
  """

  def change do
    alter table(:scores) do
      remove :revealed, :boolean, default: false
    end
  end
end
