defmodule Portal.Repo.Migrations.RemoveDeferredTools do
  use Ecto.Migration

  def up do
    for id <- ~w(org_design collaboration_designer org_cadence) do
      execute "DELETE FROM user_tool_interests WHERE tool_id = '#{id}'"
      execute "DELETE FROM tools WHERE id = '#{id}'"
    end
  end

  def down do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_string()

    repo().query!("""
    INSERT INTO tools (id, name, tagline, description, audience, default_status, category, sort_order, admin_enabled, inserted_at, updated_at) VALUES
    ('org_design', 'Org Design', 'Design democratic organisations', 'Apply Open Systems Theory to design organisations where people manage their own work. Map organisational structure, identify design improvements, and plan transitions.', 'facilitator', 'coming_soon', 'workshop_management', 4, true, '#{now}', '#{now}'),
    ('collaboration_designer', 'Collaboration Designer', 'Design effective collaboration patterns', 'Map how teams and groups need to work together. Design collaboration patterns that support coordination without creating unnecessary dependencies or hierarchy.', 'facilitator', 'coming_soon', 'workshop_management', 5, true, '#{now}', '#{now}'),
    ('org_cadence', 'Org Cadence', 'Align organisational rhythms', 'Establish healthy meeting rhythms and communication patterns across the organisation. Ensure information flows where it needs to without drowning people in meetings.', 'facilitator', 'coming_soon', 'workshop_management', 6, true, '#{now}', '#{now}')
    """)
  end
end
