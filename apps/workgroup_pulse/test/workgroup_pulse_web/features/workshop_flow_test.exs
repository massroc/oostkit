defmodule WorkgroupPulseWeb.Features.WorkshopFlowTest do
  use WorkgroupPulseWeb.FeatureCase, async: false

  import Wallaby.Query
  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Workshops.{Question, Template}

  setup do
    slug = "six-criteria-#{System.unique_integer([:positive])}"

    template =
      Repo.insert!(%Template{
        name: "Six Criteria Test",
        slug: slug,
        version: "1.0.0",
        default_duration_minutes: 210
      })

    Repo.insert!(%Question{
      template_id: template.id,
      index: 0,
      title: "Elbow Room",
      criterion_number: "1",
      criterion_name: "Elbow Room",
      explanation: "Test explanation",
      scale_type: "balance",
      scale_min: -5,
      scale_max: 5,
      optimal_value: 0
    })

    %{template: template}
  end

  @tag :e2e
  feature "user can create a new workshop session", %{session: session} do
    session
    |> visit("/")
    |> assert_has(css("h1", text: "Productive Work Groups"))
    |> click(link("Start New Workshop"))
    |> assert_has(css("h1", text: "Create New Workshop"))
  end

  @tag :e2e
  feature "user can join an existing session", %{session: session, template: template} do
    # Create a session directly via context
    {:ok, workshop_session} = WorkgroupPulse.Sessions.create_session(template)

    # Visit the join page directly
    session
    |> visit("/session/#{workshop_session.code}/join")
    |> assert_has(css("h1", text: "Join Workshop"))
    |> fill_in(text_field("participant[name]"), with: "Alice")
    |> click(button("Join Workshop"))
    |> assert_has(css("h1", text: "Waiting Room"))
    |> assert_has(css("span", text: "Alice"))
  end

  @tag :e2e
  feature "home page displays correctly", %{session: session} do
    session
    |> visit("/")
    |> assert_has(css("h1", text: "Productive Work Groups"))
    |> assert_has(link("Start New Workshop"))
  end
end
