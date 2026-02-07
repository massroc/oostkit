defmodule WorkgroupPulseWeb.Features.FullWorkshopFlowTest do
  @moduledoc """
  End-to-end integration test for the complete workshop lifecycle.

  Uses a minimal 2-question template (1 balance + 1 maximal) and 2 participants
  (facilitator + Alice) to exercise every phase transition, both scale types,
  the mid-transition interstitial, turn-based scoring, readiness, and all navigation.

  Flow: Lobby → Intro → Scoring Q1 → Scoring Q2 → Summary → Completed → Finish
  """
  use WorkgroupPulseWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulse.Workshops.{Question, Template}

  setup do
    slug = "e2e-flow-#{System.unique_integer([:positive])}"

    template =
      Repo.insert!(%Template{
        name: "E2E Flow Test",
        slug: slug,
        version: "1.0.0",
        default_duration_minutes: 60
      })

    # Q0: balance scale (-5 to +5)
    Repo.insert!(%Question{
      template_id: template.id,
      index: 0,
      title: "Elbow Room",
      criterion_number: "1",
      criterion_name: "Elbow Room",
      explanation: "How much latitude does the team have?",
      scale_type: "balance",
      scale_min: -5,
      scale_max: 5,
      optimal_value: 0
    })

    # Q1: maximal scale (0 to 10) — triggers mid-transition interstitial
    Repo.insert!(%Question{
      template_id: template.id,
      index: 1,
      title: "Goals",
      criterion_number: "5a",
      criterion_name: "Goals",
      explanation: "How clear are the team's goals?",
      scale_type: "maximal",
      scale_min: 0,
      scale_max: 10,
      optimal_value: nil
    })

    {:ok, session} =
      Sessions.create_session(template, duration_minutes: 60, timer_enabled: false)

    fac_token = Ecto.UUID.generate()

    {:ok, facilitator} =
      Sessions.join_session(session, "Facilitator", fac_token, is_facilitator: true)

    alice_token = Ecto.UUID.generate()
    {:ok, alice} = Sessions.join_session(session, "Alice", alice_token)

    %{
      session: session,
      fac_token: fac_token,
      alice_token: alice_token,
      facilitator: facilitator,
      alice: alice
    }
  end

  describe "full workshop lifecycle" do
    test "drives through lobby → intro → scoring → summary → completed → finish", %{
      conn: conn,
      session: session,
      fac_token: fac_token,
      alice_token: alice_token
    } do
      # ─── Connect both participants ───────────────────────────────────
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      alice_conn = Plug.Test.init_test_session(build_conn(), %{browser_token: alice_token})

      {:ok, fac_view, fac_html} = live(fac_conn, ~p"/session/#{session.code}")
      {:ok, alice_view, alice_html} = live(alice_conn, ~p"/session/#{session.code}")

      # ─── Phase 1: Lobby ─────────────────────────────────────────────
      assert fac_html =~ "Waiting Room"
      assert alice_html =~ "Waiting Room"

      # Only facilitator sees Start Workshop
      assert fac_html =~ "Start Workshop"
      refute alice_html =~ "Start Workshop"

      # ─── Phase 2: Start → Intro ────────────────────────────────────
      fac_view |> element("button", "Start Workshop") |> render_click()

      # Flush PubSub to Alice's view
      render(alice_view)

      assert render(fac_view) =~ "Welcome to the Workshop"
      assert render(alice_view) =~ "Welcome to the Workshop"

      # ─── Phase 3: Skip Intro → Scoring Q1 ──────────────────────────
      fac_view |> element("button[phx-click='skip_intro']") |> render_click()

      # Flush PubSub to Alice
      render(alice_view)

      fac_html = render(fac_view)
      alice_html = render(alice_view)

      assert fac_html =~ "Elbow Room"
      assert alice_html =~ "Elbow Room"
      assert fac_html =~ "Balance Scale"

      # ─── Phase 4: Q1 — Facilitator scores (turn 1) ─────────────────
      # Turn order: Facilitator first (joined first), then Alice
      # Facilitator should see "Click to score" on their cell
      assert fac_html =~ "Click to"

      # Open overlay and select score 0 (submits immediately via select_score)
      fac_view |> element("[phx-click='edit_my_score']") |> render_click()
      fac_view |> element("button[phx-value-score='0']") |> render_click()

      # Should see "Done" button after submitting
      assert render(fac_view) =~ "Done"

      # Click Done to complete facilitator's turn
      fac_view |> element("button", "Done") |> render_click()

      # Flush PubSub — Alice should now see it's her turn
      render(alice_view)

      # ─── Phase 5: Q1 — Alice scores (turn 2) ───────────────────────
      alice_html = render(alice_view)
      assert alice_html =~ "Click to"

      # Alice opens overlay and selects -1
      alice_view |> element("[phx-click='edit_my_score']") |> render_click()
      alice_view |> element("button[phx-value-score='-1']") |> render_click()

      # Alice clicks Done
      assert render(alice_view) =~ "Done"
      alice_view |> element("button", "Done") |> render_click()

      # Flush PubSub to facilitator
      render(fac_view)

      # All turns complete — scores should be revealed
      # Facilitator should see "Next Question" (not last question)
      fac_html = render(fac_view)
      assert fac_html =~ "Next Question"

      # ─── Phase 6: Q1 — Alice marks ready ───────────────────────────
      # Alice should see "I'm Ready" button (non-facilitator, scores revealed)
      alice_html = render(alice_view)
      assert alice_html =~ "I&#39;m Ready" or alice_html =~ "I'm Ready"

      alice_view |> element("button[phx-click='mark_ready']") |> render_click()

      # Flush PubSub to facilitator
      render(fac_view)

      # Facilitator should see "All participants ready"
      fac_html = render(fac_view)
      assert fac_html =~ "All participants ready" or fac_html =~ "1/1 ready"

      # ─── Phase 7: Advance to Q2 → Mid-transition ───────────────────
      # Since Q1 is balance and Q2 is maximal, mid-transition should show
      fac_view |> element("button", "Next Question") |> render_click()

      # Flush PubSub to Alice
      render(alice_view)

      fac_html = render(fac_view)
      alice_html = render(alice_view)

      assert fac_html =~ "New Scoring Scale Ahead"
      assert alice_html =~ "New Scoring Scale Ahead"

      # Dynamic question number (not hardcoded "Question 5")
      assert fac_html =~ "Continue to Question 2"

      # ─── Phase 8: Dismiss transition ────────────────────────────────
      fac_view |> render_click("continue_past_transition")
      alice_view |> render_click("continue_past_transition")

      fac_html = render(fac_view)
      alice_html = render(alice_view)

      assert fac_html =~ "Goals"
      assert alice_html =~ "Goals"
      assert fac_html =~ "Maximal Scale"

      # ─── Phase 9: Q2 — Facilitator scores (turn 1) ─────────────────
      assert fac_html =~ "Click to"

      fac_view |> element("[phx-click='edit_my_score']") |> render_click()
      fac_view |> element("button[phx-value-score='7']") |> render_click()

      assert render(fac_view) =~ "Done"
      fac_view |> element("button", "Done") |> render_click()

      # Flush PubSub
      render(alice_view)

      # ─── Phase 10: Q2 — Alice scores (turn 2) ──────────────────────
      alice_html = render(alice_view)
      assert alice_html =~ "Click to"

      alice_view |> element("[phx-click='edit_my_score']") |> render_click()
      alice_view |> element("button[phx-value-score='8']") |> render_click()

      assert render(alice_view) =~ "Done"
      alice_view |> element("button", "Done") |> render_click()

      # Flush PubSub
      render(fac_view)

      # All turns complete on last question — facilitator should see "Continue to Summary"
      fac_html = render(fac_view)
      assert fac_html =~ "Continue to Summary"

      # ─── Phase 11: Q2 — Alice marks ready ──────────────────────────
      alice_view |> element("button[phx-click='mark_ready']") |> render_click()
      render(fac_view)

      # ─── Phase 12: Advance to Summary ──────────────────────────────
      fac_view |> element("button", "Continue to Summary") |> render_click()
      render(alice_view)

      fac_html = render(fac_view)
      alice_html = render(alice_view)

      assert fac_html =~ "Workshop Summary"
      assert alice_html =~ "Workshop Summary"

      # Facilitator should see "Continue to Wrap-Up"
      assert fac_html =~ "Continue to Wrap-Up"

      # ─── Phase 13: Advance to Completed ────────────────────────────
      fac_view |> element("button", "Continue to Wrap-Up") |> render_click()
      render(alice_view)

      fac_html = render(fac_view)
      alice_html = render(alice_view)

      assert fac_html =~ "Workshop Wrap-Up" or fac_html =~ "Wrap-Up"
      assert alice_html =~ "Workshop Wrap-Up" or alice_html =~ "Wrap-Up"

      # Facilitator should see Finish Workshop
      assert fac_html =~ "Finish Workshop"

      # ─── Phase 14: Finish → Redirect ───────────────────────────────
      assert {:error, {:live_redirect, %{to: "/"}}} =
               fac_view |> element("button", "Finish Workshop") |> render_click()
    end
  end
end
