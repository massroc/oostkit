defmodule Portal.Repo.Migrations.SeedTools do
  use Ecto.Migration

  def up do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    tools = [
      %{
        id: "workgroup_pulse",
        name: "Workgroup Pulse",
        tagline: "6 Criteria for Productive Work",
        description:
          "Find out how your team is really doing. The 6 Criteria reveal whether people " <>
            "have what they need to do productive, self-managing work. Run a quick assessment, " <>
            "discuss the results together, and agree on actions.",
        url: "https://pulse.oostkit.com",
        audience: "team",
        default_status: "live",
        sort_order: 1,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: "wrt",
        name: "Workshop Referral Tool",
        tagline: "Participative selection for design workshops",
        description:
          "Let the network decide who should be in the room. Manage the referral process " <>
            "for Participative Design Workshops — facilitators set up nomination rounds, " <>
            "send invitations, and collect peer nominations to build the ideal participant list.",
        url: "https://wrt.oostkit.com",
        audience: "facilitator",
        default_status: "coming_soon",
        sort_order: 2,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: "search_conference",
        name: "Search Conference",
        tagline: "Collaborative strategic planning",
        description:
          "Bring people together to search for common ground and develop shared action plans. " <>
            "The Search Conference method helps groups find agreement on desirable futures and " <>
            "concrete steps to get there.",
        url: nil,
        audience: "facilitator",
        default_status: "coming_soon",
        sort_order: 3,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: "team_kickoff",
        name: "Team Kick-off",
        tagline: "Launch self-managing teams",
        description:
          "Give new teams the foundation they need to self-manage from day one. " <>
            "Structured kick-off sessions that establish shared purpose, goals, and ways of working.",
        url: nil,
        audience: "team",
        default_status: "coming_soon",
        sort_order: 4,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: "team_design",
        name: "Team Design",
        tagline: "Design teams for productive work",
        description:
          "Structure teams around whole tasks with the right mix of skills and authority. " <>
            "Apply design principles that enable genuine self-management and productive work.",
        url: nil,
        audience: "facilitator",
        default_status: "coming_soon",
        sort_order: 5,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: "org_design",
        name: "Org Design",
        tagline: "Design democratic organisations",
        description:
          "Apply Open Systems Theory to design organisations where people manage their own work. " <>
            "Map organisational structure, identify design improvements, and plan transitions.",
        url: nil,
        audience: "facilitator",
        default_status: "coming_soon",
        sort_order: 6,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: "skill_matrix",
        name: "Skill Matrix",
        tagline: "Map and develop team capabilities",
        description:
          "Make skills visible across the team. Track who can do what, identify gaps, " <>
            "and plan multiskilling so the team can flexibly handle the full range of work.",
        url: nil,
        audience: "team",
        default_status: "coming_soon",
        sort_order: 7,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: "dp1_briefing",
        name: "DP1 Briefing",
        tagline: "Understand bureaucratic design",
        description:
          "Learn to recognise Design Principle 1 — redundancy of parts — and understand " <>
            "why it limits productivity and engagement. Essential context before redesigning.",
        url: nil,
        audience: "team",
        default_status: "coming_soon",
        sort_order: 8,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: "dp2_briefing",
        name: "DP2 Briefing",
        tagline: "Understand democratic design",
        description:
          "Learn Design Principle 2 — redundancy of functions — the foundation of " <>
            "self-managing teams. Understand what it takes to design organisations where " <>
            "people control and coordinate their own work.",
        url: nil,
        audience: "team",
        default_status: "coming_soon",
        sort_order: 9,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: "collaboration_designer",
        name: "Collaboration Designer",
        tagline: "Design effective collaboration patterns",
        description:
          "Map how teams and groups need to work together. Design collaboration patterns " <>
            "that support coordination without creating unnecessary dependencies or hierarchy.",
        url: nil,
        audience: "facilitator",
        default_status: "coming_soon",
        sort_order: 10,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: "org_cadence",
        name: "Org Cadence",
        tagline: "Align organisational rhythms",
        description:
          "Establish healthy meeting rhythms and communication patterns across the organisation. " <>
            "Ensure information flows where it needs to without drowning people in meetings.",
        url: nil,
        audience: "facilitator",
        default_status: "coming_soon",
        sort_order: 11,
        admin_enabled: true,
        inserted_at: now,
        updated_at: now
      }
    ]

    repo().insert_all("tools", tools, on_conflict: :nothing)
  end

  def down do
    execute "DELETE FROM tools"
  end
end
