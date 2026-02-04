defmodule WorkgroupPulse.Repo.Migrations.RemoveCatchUpPhaseField do
  use Ecto.Migration

  @moduledoc """
  Removes the in_catch_up_phase field from sessions.

  This field was part of the original planning poker-style flow where
  skipped participants could catch up later. The simplified turn-based
  flow no longer uses this feature - participants who miss their turn
  are simply skipped.
  """

  def change do
    alter table(:sessions) do
      remove :in_catch_up_phase, :boolean, default: false
    end
  end
end
