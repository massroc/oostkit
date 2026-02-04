defmodule WorkgroupPulse.Repo.Migrations.AddTurnBasedScoringFields do
  @moduledoc """
  Add fields to support turn-based sequential scoring.

  This migration adds:
  - current_turn_index: tracks whose turn it is to score (index into participant list)
  - in_catch_up_phase: whether we're in the catch-up phase for skipped participants
  - turn_locked: whether a participant has clicked "Done" for their turn
  - row_locked: whether a row/question has been permanently locked
  """
  use Ecto.Migration

  def change do
    # Add turn tracking to sessions
    alter table(:sessions) do
      add :current_turn_index, :integer, default: 0
      add :in_catch_up_phase, :boolean, default: false
    end

    # Add turn and row locking to scores
    alter table(:scores) do
      add :turn_locked, :boolean, default: false
      add :row_locked, :boolean, default: false
    end
  end
end
