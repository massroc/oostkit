defmodule Portal.Repo.Migrations.AddToolCategories do
  use Ecto.Migration

  def up do
    alter table(:tools) do
      add :category, :string, null: false, default: "workshop_management"
    end

    drop unique_index(:tools, [:sort_order])
    flush()

    # Assign categories and per-category sort_order
    # Learning
    execute "UPDATE tools SET category = 'learning', sort_order = 2 WHERE id = 'dp1_briefing'"
    execute "UPDATE tools SET category = 'learning', sort_order = 3 WHERE id = 'dp2_briefing'"

    # Workshop Management
    execute "UPDATE tools SET category = 'workshop_management', sort_order = 1 WHERE id = 'search_conference'"
    execute "UPDATE tools SET category = 'workshop_management', sort_order = 2 WHERE id = 'wrt'"
    execute "UPDATE tools SET category = 'workshop_management', sort_order = 3 WHERE id = 'skill_matrix'"
    execute "UPDATE tools SET category = 'workshop_management', sort_order = 4 WHERE id = 'org_design'"

    execute "UPDATE tools SET category = 'workshop_management', sort_order = 5 WHERE id = 'collaboration_designer'"

    execute "UPDATE tools SET category = 'workshop_management', sort_order = 6 WHERE id = 'org_cadence'"

    # Team Workshops
    execute "UPDATE tools SET category = 'team_workshops', sort_order = 1 WHERE id = 'team_design'"
    execute "UPDATE tools SET category = 'team_workshops', sort_order = 2 WHERE id = 'team_kickoff'"
    execute "UPDATE tools SET category = 'team_workshops', sort_order = 3 WHERE id = 'workgroup_pulse'"

    # Insert new tool: Introduction to Open Systems Thinking
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    repo().insert_all("tools", [
      %{
        id: "intro_ost",
        name: "Introduction to Open Systems Thinking",
        tagline: "Learn the foundations of democratic organisation design",
        description:
          "An interactive introduction to Open Systems Theory and the design principles " <>
            "that underpin genuinely democratic, self-managing organisations. Essential " <>
            "grounding before using the design and facilitation tools.",
        url: nil,
        audience: "team",
        default_status: "coming_soon",
        category: "learning",
        sort_order: 1,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      }
    ])

    create unique_index(:tools, [:category, :sort_order])
  end

  def down do
    drop unique_index(:tools, [:category, :sort_order])

    repo().delete_all("tools", [id: "intro_ost"])
    execute "DELETE FROM tools WHERE id = 'intro_ost'"

    # Restore original flat sort_order
    execute "UPDATE tools SET sort_order = 1 WHERE id = 'workgroup_pulse'"
    execute "UPDATE tools SET sort_order = 2 WHERE id = 'wrt'"
    execute "UPDATE tools SET sort_order = 3 WHERE id = 'search_conference'"
    execute "UPDATE tools SET sort_order = 4 WHERE id = 'team_kickoff'"
    execute "UPDATE tools SET sort_order = 5 WHERE id = 'team_design'"
    execute "UPDATE tools SET sort_order = 6 WHERE id = 'org_design'"
    execute "UPDATE tools SET sort_order = 7 WHERE id = 'skill_matrix'"
    execute "UPDATE tools SET sort_order = 8 WHERE id = 'dp1_briefing'"
    execute "UPDATE tools SET sort_order = 9 WHERE id = 'dp2_briefing'"
    execute "UPDATE tools SET sort_order = 10 WHERE id = 'collaboration_designer'"
    execute "UPDATE tools SET sort_order = 11 WHERE id = 'org_cadence'"

    create unique_index(:tools, [:sort_order])

    alter table(:tools) do
      remove :category
    end
  end
end
