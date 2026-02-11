# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias Portal.Tools

tools = [
  %{
    id: "workgroup_pulse",
    name: "Workgroup Pulse",
    tagline: "6 Criteria for Productive Work",
    description: """
    Find out how your team is really doing. The 6 Criteria reveal whether people \
    have what they need to do productive, self-managing work. Run a quick assessment, \
    discuss the results together, and agree on actions.\
    """,
    url: "https://pulse.oostkit.com",
    audience: "team",
    default_status: "live",
    sort_order: 1
  },
  %{
    id: "wrt",
    name: "Workshop Referral Tool",
    tagline: "Participative selection for design workshops",
    description: """
    Let the network decide who should be in the room. Manage the referral process \
    for Participative Design Workshops — facilitators set up nomination rounds, \
    send invitations, and collect peer nominations to build the ideal participant list.\
    """,
    url: "https://wrt.oostkit.com",
    audience: "facilitator",
    default_status: "coming_soon",
    sort_order: 2
  },
  %{
    id: "search_conference",
    name: "Search Conference",
    tagline: "Collaborative strategic planning",
    description: """
    Bring people together to search for common ground and develop shared action plans. \
    The Search Conference method helps groups find agreement on desirable futures and \
    concrete steps to get there.\
    """,
    audience: "facilitator",
    default_status: "coming_soon",
    sort_order: 3
  },
  %{
    id: "team_kickoff",
    name: "Team Kick-off",
    tagline: "Launch self-managing teams",
    description: """
    Give new teams the foundation they need to self-manage from day one. \
    Structured kick-off sessions that establish shared purpose, goals, and ways of working.\
    """,
    audience: "team",
    default_status: "coming_soon",
    sort_order: 4
  },
  %{
    id: "team_design",
    name: "Team Design",
    tagline: "Design teams for productive work",
    description: """
    Structure teams around whole tasks with the right mix of skills and authority. \
    Apply design principles that enable genuine self-management and productive work.\
    """,
    audience: "facilitator",
    default_status: "coming_soon",
    sort_order: 5
  },
  %{
    id: "org_design",
    name: "Org Design",
    tagline: "Design democratic organisations",
    description: """
    Apply Open Systems Theory to design organisations where people manage their own work. \
    Map organisational structure, identify design improvements, and plan transitions.\
    """,
    audience: "facilitator",
    default_status: "coming_soon",
    sort_order: 6
  },
  %{
    id: "skill_matrix",
    name: "Skill Matrix",
    tagline: "Map and develop team capabilities",
    description: """
    Make skills visible across the team. Track who can do what, identify gaps, \
    and plan multiskilling so the team can flexibly handle the full range of work.\
    """,
    audience: "team",
    default_status: "coming_soon",
    sort_order: 7
  },
  %{
    id: "dp1_briefing",
    name: "DP1 Briefing",
    tagline: "Understand bureaucratic design",
    description: """
    Learn to recognise Design Principle 1 — redundancy of parts — and understand \
    why it limits productivity and engagement. Essential context before redesigning.\
    """,
    audience: "team",
    default_status: "coming_soon",
    sort_order: 8
  },
  %{
    id: "dp2_briefing",
    name: "DP2 Briefing",
    tagline: "Understand democratic design",
    description: """
    Learn Design Principle 2 — redundancy of functions — the foundation of \
    self-managing teams. Understand what it takes to design organisations where \
    people control and coordinate their own work.\
    """,
    audience: "team",
    default_status: "coming_soon",
    sort_order: 9
  },
  %{
    id: "collaboration_designer",
    name: "Collaboration Designer",
    tagline: "Design effective collaboration patterns",
    description: """
    Map how teams and groups need to work together. Design collaboration patterns \
    that support coordination without creating unnecessary dependencies or hierarchy.\
    """,
    audience: "facilitator",
    default_status: "coming_soon",
    sort_order: 10
  },
  %{
    id: "org_cadence",
    name: "Org Cadence",
    tagline: "Align organisational rhythms",
    description: """
    Establish healthy meeting rhythms and communication patterns across the organisation. \
    Ensure information flows where it needs to without drowning people in meetings.\
    """,
    audience: "facilitator",
    default_status: "coming_soon",
    sort_order: 11
  }
]

for tool_attrs <- tools do
  Tools.upsert_tool(tool_attrs)
end

IO.puts("Seeded #{length(tools)} tools")
