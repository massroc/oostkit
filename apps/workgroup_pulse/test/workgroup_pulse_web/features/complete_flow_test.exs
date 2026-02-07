defmodule WorkgroupPulseWeb.Features.CompleteFlowTest do
  @moduledoc """
  Integration tests for workshop flow through state transitions.
  Tests verify state transitions work correctly after refactoring to handler modules.
  """
  use WorkgroupPulseWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulse.Workshops.{Question, Template}

  describe "workshop state transitions" do
    setup do
      slug = "flow-test-#{System.unique_integer([:positive])}"

      template =
        Repo.insert!(%Template{
          name: "Flow Test",
          slug: slug,
          version: "1.0.0",
          default_duration_minutes: 60
        })

      Repo.insert!(%Question{
        template_id: template.id,
        index: 0,
        title: "Test Question",
        criterion_number: "1",
        criterion_name: "Test",
        explanation: "Test explanation",
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        optimal_value: 0
      })

      %{template: template}
    end

    test "facilitator can start workshop and navigate intro", %{conn: conn, template: template} do
      {:ok, session} =
        Sessions.create_session(template, duration_minutes: 60, timer_enabled: false)

      fac_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Facilitator", fac_token, is_facilitator: true)

      # Add a participant so facilitator can start
      part_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Alice", part_token)

      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, html} = live(fac_conn, ~p"/session/#{session.code}")

      # Start in lobby
      assert html =~ "Waiting Room"

      # Start workshop
      view |> element("button", "Start Workshop") |> render_click()
      assert render(view) =~ "Welcome to the Workshop"

      # Navigate through intro steps (use events directly since carousel renders all slides)
      view |> render_click("intro_next")
      assert render(view) =~ "How This Workshop Works"

      view |> render_click("intro_next")
      assert render(view) =~ "balance"

      view |> render_click("intro_next")
      assert render(view) =~ "Safe Space" or render(view) =~ "honest"

      # Continue to scoring
      view |> render_click("continue_to_scoring")
      assert render(view) =~ "Test Question"
    end

    test "facilitator can use go_back from intro", %{conn: conn, template: template} do
      {:ok, session} =
        Sessions.create_session(template, duration_minutes: 60, timer_enabled: false)

      fac_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Facilitator", fac_token, is_facilitator: true)

      part_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Alice", part_token)

      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _} = live(fac_conn, ~p"/session/#{session.code}")

      # Start workshop and go to intro
      view |> element("button", "Start Workshop") |> render_click()
      assert render(view) =~ "Welcome to the Workshop"

      # Go to step 2
      view |> render_click("intro_next")
      assert render(view) =~ "How This Workshop Works"

      # Go back via carousel navigate (click on non-active slide fires this event)
      view |> render_click("carousel_navigate", %{"index" => 0, "carousel" => "workshop-carousel"})
      assert render(view) =~ "Welcome to the Workshop"
    end

    test "facilitator can skip intro directly to scoring", %{conn: conn, template: template} do
      {:ok, session} =
        Sessions.create_session(template, duration_minutes: 60, timer_enabled: false)

      fac_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Facilitator", fac_token, is_facilitator: true)

      part_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Alice", part_token)

      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _} = live(fac_conn, ~p"/session/#{session.code}")

      # Start workshop
      view |> element("button", "Start Workshop") |> render_click()
      assert render(view) =~ "Welcome to the Workshop"

      # Skip intro goes directly to scoring
      view |> element("button[phx-click='skip_intro']") |> render_click()
      assert render(view) =~ "Test Question"
    end

    test "participant joins and sees lobby correctly", %{conn: conn, template: template} do
      {:ok, session} =
        Sessions.create_session(template, duration_minutes: 60, timer_enabled: false)

      fac_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Facilitator", fac_token, is_facilitator: true)

      part_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Alice", part_token)

      part_conn = Plug.Test.init_test_session(conn, %{browser_token: part_token})
      {:ok, _view, html} = live(part_conn, ~p"/session/#{session.code}")

      # Should see lobby
      assert html =~ "Waiting Room"
      # Should see both participants
      assert html =~ "Facilitator"
      assert html =~ "Alice"
      # Should not see start button (not facilitator)
      refute html =~ "Start Workshop"
    end
  end

  describe "scoring state" do
    setup do
      slug = "scoring-test-#{System.unique_integer([:positive])}"

      template =
        Repo.insert!(%Template{
          name: "Scoring Test",
          slug: slug,
          version: "1.0.0",
          default_duration_minutes: 60
        })

      Repo.insert!(%Question{
        template_id: template.id,
        index: 0,
        title: "Test Question",
        criterion_number: "1",
        criterion_name: "Test",
        explanation: "Test",
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        optimal_value: 0
      })

      # Start session in scoring state
      {:ok, session} =
        Sessions.create_session(template, duration_minutes: 60, timer_enabled: false)

      fac_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Facilitator", fac_token, is_facilitator: true)

      part_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Alice", part_token)

      {:ok, session} = Sessions.start_session(session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      %{session: session, fac_token: fac_token, part_token: part_token}
    end

    test "facilitator can select and submit score", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _} = live(fac_conn, ~p"/session/#{session.code}")

      # Should see scoring UI with Test Question
      assert render(view) =~ "Test Question"

      # Click "Click to score" to open overlay, then select a score
      view |> element("[phx-click='edit_my_score']") |> render_click()
      view |> element("button[phx-value-score='0']") |> render_click()
      # The score should now appear in the grid and Done button should be visible
      html = render(view)
      assert html =~ "Done"
    end

    test "back button is not shown on Q1 scoring", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, _view, html} = live(fac_conn, ~p"/session/#{session.code}")

      # Should be on scoring with Test Question visible
      assert html =~ "Test Question"

      # Back button should not be present on Q1
      refute html =~ "go_back"
    end
  end
end
