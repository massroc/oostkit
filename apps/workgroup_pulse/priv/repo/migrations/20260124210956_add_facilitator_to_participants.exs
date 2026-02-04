defmodule WorkgroupPulse.Repo.Migrations.AddFacilitatorToParticipants do
  use Ecto.Migration

  def change do
    alter table(:participants) do
      add :is_facilitator, :boolean, default: false, null: false
    end

    # Create index for quickly finding the facilitator of a session
    create index(:participants, [:session_id, :is_facilitator],
             where: "is_facilitator = true",
             name: :participants_session_facilitator_index)
  end
end
