defmodule ProductiveWorkgroupsWeb.SessionLiveTest do
  use ProductiveWorkgroupsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias ProductiveWorkgroups.{Notes, Scoring, Sessions, Workshops}

  describe "SessionLive.New" do
    setup do
      # Create the Six Criteria template for testing
      {:ok, template} =
        Workshops.create_template(%{
          name: "Six Criteria Test",
          slug: "six-criteria",
          version: "1.0.0",
          default_duration_minutes: 210
        })

      # Create at least one question for the template
      {:ok, _} =
        Workshops.create_question(template, %{
          index: 0,
          title: "Test Question",
          criterion_number: "1",
          criterion_name: "Test Criterion",
          explanation: "Test explanation",
          scale_type: "balance",
          scale_min: -5,
          scale_max: 5,
          optimal_value: 0
        })

      %{template: template}
    end

    test "renders the session creation form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/session/new")

      assert html =~ "Create New Workshop"
      assert html =~ "Create Workshop"
      assert html =~ "Your Name (Facilitator)"
      assert html =~ "Session Timer"
    end
  end

  describe "SessionController.create" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Controller Create Test",
          slug: "six-criteria",
          version: "1.0.0",
          default_duration_minutes: 210
        })

      %{template: template}
    end

    test "creates session and joins as facilitator", %{conn: conn} do
      conn =
        post(conn, ~p"/session/create", %{facilitator_name: "Facilitator Jane", duration: "120"})

      # Should redirect to the session page
      assert to = redirected_to(conn)
      assert to =~ ~r/\/session\/[A-Z0-9]+$/

      # Should have browser token
      assert get_session(conn, :browser_token)

      # Extract the code and verify participant is facilitator
      [_, code] = Regex.run(~r/\/session\/([A-Z0-9]+)$/, to)
      session = Sessions.get_session_by_code(code)
      participant = Sessions.get_facilitator(session)
      assert participant.name == "Facilitator Jane"
      assert participant.is_facilitator == true
    end

    test "requires a name to create session", %{conn: conn} do
      conn = post(conn, ~p"/session/create", %{facilitator_name: "", duration: "210"})

      assert redirected_to(conn) == "/session/new"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "name is required"
    end
  end

  describe "SessionController.create without template" do
    test "handles missing template gracefully", %{conn: conn} do
      # No template setup - simulates missing seeds
      conn = post(conn, ~p"/session/create", %{facilitator_name: "Test User", duration: "210"})

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Workshop template not available"
    end
  end

  describe "SessionLive.Join" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Join Test",
          slug: "join-test",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      {:ok, session} = Sessions.create_session(template)
      %{session: session, template: template}
    end

    test "renders the join form", %{conn: conn, session: session} do
      {:ok, _view, html} = live(conn, ~p"/session/#{session.code}/join")

      assert html =~ "Join Workshop"
      assert html =~ session.code
      assert html =~ "Your Name"
    end

    test "handles invalid session code gracefully", %{conn: conn} do
      {:error, {:redirect, %{to: "/", flash: flash}}} =
        live(conn, ~p"/session/INVALID/join")

      assert flash["error"] =~ "Session not found"
    end
  end

  describe "SessionController.join" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Controller Join Test",
          slug: "controller-join-test",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      {:ok, session} = Sessions.create_session(template)
      %{session: session, template: template}
    end

    test "joins session with valid name and redirects", %{conn: conn, session: session} do
      conn = post(conn, ~p"/session/#{session.code}/join", %{participant: %{name: "Alice"}})

      assert redirected_to(conn) == "/session/#{session.code}"
      assert get_session(conn, :browser_token)
    end

    test "requires a name to join", %{conn: conn, session: session} do
      conn = post(conn, ~p"/session/#{session.code}/join", %{participant: %{name: ""}})

      assert redirected_to(conn) == "/session/#{session.code}/join"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Name is required"
    end

    test "handles invalid session code", %{conn: conn} do
      conn = post(conn, ~p"/session/INVALID/join", %{participant: %{name: "Alice"}})

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Session not found"
    end
  end

  describe "SessionLive.Show" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Show Test",
          slug: "show-test",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      {:ok, _} =
        Workshops.create_question(template, %{
          index: 0,
          title: "Q1",
          criterion_number: "1",
          criterion_name: "C1",
          explanation: "E1",
          scale_type: "balance",
          scale_min: -5,
          scale_max: 5,
          optimal_value: 0
        })

      {:ok, session} = Sessions.create_session(template)
      {:ok, participant} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())

      %{session: session, participant: participant, template: template}
    end

    test "redirects to join if no browser token", %{conn: conn, session: session} do
      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/session/#{session.code}")
      assert to == "/session/#{session.code}/join"
    end

    test "renders lobby phase for participants", %{
      conn: conn,
      session: session,
      participant: participant
    } do
      # Set the browser token in the session
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, participant.browser_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{session.code}")

      assert html =~ "Waiting Room"
      assert html =~ "Alice"
    end

    test "shows participant list in lobby", %{
      conn: conn,
      session: session,
      participant: participant
    } do
      # Add another participant
      {:ok, _p2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, participant.browser_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{session.code}")

      assert html =~ "Alice"
      assert html =~ "Bob"
    end

    test "handles invalid session code", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{})

      {:error, {:redirect, %{to: "/", flash: flash}}} =
        live(conn, ~p"/session/BADCODE")

      assert flash["error"] =~ "Session not found"
    end

    test "shows Start Workshop button for facilitator", %{conn: conn, session: session} do
      # Create a facilitator
      facilitator_token = Ecto.UUID.generate()

      {:ok, _facilitator} =
        Sessions.join_session(session, "Lead", facilitator_token, is_facilitator: true)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{session.code}")

      assert html =~ "Start Workshop"
      assert html =~ "Facilitator"
    end

    test "does not show Start Workshop button for regular participant", %{
      conn: conn,
      session: session,
      participant: participant
    } do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, participant.browser_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{session.code}")

      refute html =~ "Start Workshop"
      assert html =~ "Waiting for the facilitator"
    end

    test "facilitator can start the workshop", %{conn: conn, session: session} do
      facilitator_token = Ecto.UUID.generate()

      {:ok, _facilitator} =
        Sessions.join_session(session, "Lead", facilitator_token, is_facilitator: true)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, facilitator_token)

      {:ok, view, _html} = live(conn, ~p"/session/#{session.code}")

      # Click Start Workshop
      html = render_click(view, "start_workshop")

      # Should transition to intro phase
      assert html =~ "Welcome to the Six Criteria Workshop"
    end
  end

  describe "Notes capture in scoring phase" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Notes Test",
          slug: "notes-test",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      # Add a question
      {:ok, _} =
        Workshops.create_question(template, %{
          index: 0,
          title: "Test Question",
          criterion_number: "1",
          criterion_name: "Test Criterion",
          explanation: "Test explanation",
          scale_type: "balance",
          scale_min: -5,
          scale_max: 5,
          optimal_value: 0,
          discussion_prompts: ["What do you think?"]
        })

      {:ok, session} = Sessions.create_session(template)

      # Create facilitator
      facilitator_token = Ecto.UUID.generate()

      {:ok, facilitator} =
        Sessions.join_session(session, "Facilitator", facilitator_token, is_facilitator: true)

      # Create participant
      participant_token = Ecto.UUID.generate()
      {:ok, participant} = Sessions.join_session(session, "Alice", participant_token)

      # Advance session to scoring phase
      {:ok, session} = Sessions.start_session(session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      %{
        session: session,
        template: template,
        facilitator: facilitator,
        facilitator_token: facilitator_token,
        participant: participant,
        participant_token: participant_token
      }
    end

    test "shows notes section when toggle button is clicked", ctx do
      # Submit scores for both participants and complete their turns
      {:ok, _} = Scoring.submit_score(ctx.session, ctx.facilitator, 0, 2)
      {:ok, _} = Scoring.lock_participant_turn(ctx.session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(ctx.session)
      {:ok, _} = Scoring.submit_score(session, ctx.participant, 0, -1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.participant, 0)
      {:ok, _session} = Sessions.advance_turn(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Notes are hidden by default
      refute html =~ "Capture a key discussion point"
      # Toggle button should be visible
      assert html =~ "Add Notes"

      # Click toggle to show notes
      html = view |> element("button", "Add Notes") |> render_click()

      # Notes section appears with input form
      assert html =~ "Capture a key discussion point"
    end

    test "participants can add notes", ctx do
      # Complete turns for both participants (submit score, lock turn, advance)
      {:ok, _} = Scoring.submit_score(ctx.session, ctx.facilitator, 0, 2)
      {:ok, _} = Scoring.lock_participant_turn(ctx.session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(ctx.session)
      {:ok, _} = Scoring.submit_score(session, ctx.participant, 0, -1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.participant, 0)
      {:ok, _session} = Sessions.advance_turn(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.participant_token)

      {:ok, view, _html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Toggle notes section visible
      view |> element("button", "Add Notes") |> render_click()

      # Type a note
      view |> element("input[name=note]") |> render_change(%{note: "This is a test note"})

      # Submit the note
      html = render_submit(view, "add_note", %{})

      assert html =~ "This is a test note"
      assert html =~ "Alice"

      # Verify note was persisted
      notes = Notes.list_notes_for_question(ctx.session, 0)
      assert length(notes) == 1
      assert hd(notes).content == "This is a test note"
    end

    test "participants can delete notes", ctx do
      # Complete turns for both participants (submit score, lock turn, advance)
      {:ok, _} = Scoring.submit_score(ctx.session, ctx.facilitator, 0, 2)
      {:ok, _} = Scoring.lock_participant_turn(ctx.session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(ctx.session)
      {:ok, _} = Scoring.submit_score(session, ctx.participant, 0, -1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.participant, 0)
      {:ok, _session} = Sessions.advance_turn(session)

      # Create a note
      {:ok, note} =
        Notes.create_note(ctx.session, 0, %{content: "Delete me", author_name: "Alice"})

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.participant_token)

      {:ok, view, _html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Toggle notes section visible
      view |> element("button", "Add Notes") |> render_click()

      # Delete the note
      html = render_click(view, "delete_note", %{"id" => note.id})

      refute html =~ "Delete me"

      # Verify note was deleted
      notes = Notes.list_notes_for_question(ctx.session, 0)
      assert notes == []
    end
  end

  describe "Facilitator role display" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Facilitator Role Test",
          slug: "facilitator-role-test",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      {:ok, _} =
        Workshops.create_question(template, %{
          index: 0,
          title: "Test Question",
          criterion_number: "1",
          criterion_name: "Test Criterion",
          explanation: "Test explanation",
          scale_type: "balance",
          scale_min: -5,
          scale_max: 5,
          optimal_value: 0
        })

      {:ok, session} = Sessions.create_session(template)

      %{session: session, template: template}
    end

    test "facilitator who is participating shows only Facilitator badge", %{
      conn: conn,
      session: session
    } do
      # Create facilitator who is participating (is_observer: false - the default)
      facilitator_token = Ecto.UUID.generate()

      {:ok, _facilitator} =
        Sessions.join_session(session, "Lead", facilitator_token,
          is_facilitator: true,
          is_observer: false
        )

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{session.code}")

      # Should show Facilitator badge
      assert html =~ "Facilitator"
      # Should NOT show Observer badge
      refute html =~ "Observer"
    end

    test "facilitator who is observing shows only Observer badge, not both", %{
      conn: conn,
      session: session
    } do
      # Create facilitator who is observing
      facilitator_token = Ecto.UUID.generate()

      {:ok, _facilitator} =
        Sessions.join_session(session, "Lead", facilitator_token,
          is_facilitator: true,
          is_observer: true
        )

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{session.code}")

      # Should show Observer badge (gray background)
      assert html =~ "bg-gray-600"
      assert html =~ "Observer"
      # Should NOT show Facilitator badge (purple background) - they cannot be both
      # The facilitator badge uses bg-purple-600 class
      refute html =~ "bg-purple-600"
    end

    test "facilitator defaults to participating (is_observer: false)", %{session: session} do
      # Create facilitator without specifying is_observer
      facilitator_token = Ecto.UUID.generate()

      {:ok, facilitator} =
        Sessions.join_session(session, "Lead", facilitator_token, is_facilitator: true)

      # Default should be participating (not observing)
      assert facilitator.is_facilitator == true
      assert facilitator.is_observer == false
    end

    test "regular participant is neither facilitator nor observer by default", %{session: session} do
      participant_token = Ecto.UUID.generate()

      {:ok, participant} = Sessions.join_session(session, "Alice", participant_token)

      assert participant.is_facilitator == false
      assert participant.is_observer == false
    end

    test "observer participant shows Observer badge", %{conn: conn, session: session} do
      # Create an observer who is not a facilitator
      observer_token = Ecto.UUID.generate()

      {:ok, _observer} =
        Sessions.join_session(session, "Watcher", observer_token, is_observer: true)

      # Create a facilitator so we can view the session
      facilitator_token = Ecto.UUID.generate()

      {:ok, _facilitator} =
        Sessions.join_session(session, "Lead", facilitator_token, is_facilitator: true)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{session.code}")

      # Observer participant should show Observer badge
      assert html =~ "Watcher"
      assert html =~ "Observer"
    end
  end

  describe "Mid-workshop transition" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Transition Test",
          slug: "transition-test",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      # Add questions 0-4 (need at least 5 questions to test transition)
      criterion_numbers = ["1", "2a", "2b", "3", "4"]

      for i <- 0..4 do
        scale_type = if i < 4, do: "balance", else: "maximal"
        scale_min = if i < 4, do: -5, else: 0
        scale_max = if i < 4, do: 5, else: 10
        optimal_value = if i < 4, do: 0, else: nil

        {:ok, _} =
          Workshops.create_question(template, %{
            index: i,
            title: "Question #{i + 1}",
            criterion_number: Enum.at(criterion_numbers, i),
            criterion_name: "Criterion #{i + 1}",
            explanation: "Explanation #{i + 1}",
            scale_type: scale_type,
            scale_min: scale_min,
            scale_max: scale_max,
            optimal_value: optimal_value,
            discussion_prompts: []
          })
      end

      {:ok, session} = Sessions.create_session(template)

      # Create facilitator
      facilitator_token = Ecto.UUID.generate()

      {:ok, facilitator} =
        Sessions.join_session(session, "Facilitator", facilitator_token, is_facilitator: true)

      # Advance to scoring and then to question 4 (index 3)
      {:ok, session} = Sessions.start_session(session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Advance through questions 1-3
      {:ok, _} = Scoring.submit_score(session, facilitator, 0, 0)
      {:ok, session} = Sessions.advance_question(session)

      {:ok, _} = Scoring.submit_score(session, facilitator, 1, 0)
      {:ok, session} = Sessions.advance_question(session)

      {:ok, _} = Scoring.submit_score(session, facilitator, 2, 0)
      {:ok, session} = Sessions.advance_question(session)

      # Now at question 4 (index 3) - submitting and advancing should show transition
      {:ok, _} = Scoring.submit_score(session, facilitator, 3, 0)

      %{
        session: session,
        template: template,
        facilitator: facilitator,
        facilitator_token: facilitator_token
      }
    end

    test "shows mid-workshop transition when advancing from question 4 to 5", ctx do
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, view, _html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Click next question to advance past question 4
      html = render_click(view, "next_question")

      # Should show the transition screen
      assert html =~ "New Scoring Scale Ahead"
      assert html =~ "first four questions"
      assert html =~ "more is always better"
      assert html =~ "10 is optimal"
    end

    test "continue button dismisses transition and shows question 5", ctx do
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, view, _html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Advance to show transition
      render_click(view, "next_question")

      # Click continue
      html = render_click(view, "continue_past_transition")

      # Should now show question 5
      assert html =~ "Question 5"
      refute html =~ "New Scoring Scale Ahead"
    end
  end

  describe "Facilitator back button" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Back Button Test",
          slug: "back-button-test",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      # Add 8 questions
      criterion_numbers = ["1", "2a", "2b", "3", "4", "5a", "5b", "6"]

      for i <- 0..7 do
        scale_type = if i < 4, do: "balance", else: "maximal"
        scale_min = if i < 4, do: -5, else: 0
        scale_max = if i < 4, do: 5, else: 10
        optimal_value = if i < 4, do: 0, else: nil

        {:ok, _} =
          Workshops.create_question(template, %{
            index: i,
            title: "Question #{i + 1}",
            criterion_number: Enum.at(criterion_numbers, i),
            criterion_name: "Criterion #{i + 1}",
            explanation: "Explanation #{i + 1}",
            scale_type: scale_type,
            scale_min: scale_min,
            scale_max: scale_max,
            optimal_value: optimal_value,
            discussion_prompts: []
          })
      end

      {:ok, session} = Sessions.create_session(template)

      # Create facilitator
      facilitator_token = Ecto.UUID.generate()

      {:ok, facilitator} =
        Sessions.join_session(session, "Facilitator", facilitator_token, is_facilitator: true)

      # Create regular participant
      participant_token = Ecto.UUID.generate()
      {:ok, participant} = Sessions.join_session(session, "Alice", participant_token)

      %{
        session: session,
        template: template,
        facilitator: facilitator,
        facilitator_token: facilitator_token,
        participant: participant,
        participant_token: participant_token
      }
    end

    test "back button is not shown in lobby state", ctx do
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Back button should not be visible in lobby
      refute html =~ "go_back"
    end

    test "back button is not shown to regular participants", ctx do
      # Advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.submit_score(session, ctx.participant, 0, 0)
      {:ok, _session} = Sessions.advance_question(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.participant_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Back button should not be visible to regular participants
      refute html =~ "go_back"
    end

    test "back button is shown to facilitator in scoring state", ctx do
      # Advance to scoring question 2
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.submit_score(session, ctx.participant, 0, 0)
      {:ok, _session} = Sessions.advance_question(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Back button should be visible
      assert html =~ "go_back"
      assert html =~ "Back"
    end

    test "facilitator can go back from question 2 to question 1", ctx do
      # Advance to scoring question 2
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.submit_score(session, ctx.participant, 0, 0)
      {:ok, _session} = Sessions.advance_question(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Should be at question 2
      assert html =~ "Question 2 of 8"

      # Click back
      html = render_click(view, "go_back")

      # Should now be at question 1
      assert html =~ "Question 1 of 8"
    end

    test "going back from question 1 results page goes to intro", ctx do
      # Start session and advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)
      # Submit scores and complete turns (simulating clicking "Done")
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 2)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, _} = Scoring.submit_score(session, ctx.participant, 0, -1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.participant, 0)
      {:ok, _session} = Sessions.advance_turn(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      # Load the page - should show results page since all turns complete
      {:ok, view, html} = live(conn, ~p"/session/#{ctx.session.code}")
      # Verify we're on the facilitator results view - it shows readiness status
      assert html =~ "participants ready"

      # Go back from results page - should go to intro (since this is question 1)
      html = render_click(view, "go_back")

      # Verify we're now at intro (step 4 - safe space)
      assert html =~ "Creating a Safe Space"
    end

    test "facilitator can go back from question 1 to intro", ctx do
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, _session} = Sessions.advance_to_scoring(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Should be at question 1
      assert html =~ "Question 1 of 8"

      # Click back
      html = render_click(view, "go_back")

      # Should now be at intro (step 4 - safe space)
      assert html =~ "Creating a Safe Space"
    end

    test "facilitator can go back from summary to last question", ctx do
      # Advance to summary
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)
      {:ok, _session} = Sessions.advance_to_summary(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Should be at summary
      assert html =~ "Workshop Summary"

      # Click back
      html = render_click(view, "go_back")

      # Should now be at last question (question 8)
      assert html =~ "Question 8 of 8"
    end

    test "facilitator can go back from actions to summary", ctx do
      # Advance to actions
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)
      {:ok, session} = Sessions.advance_to_summary(session)
      {:ok, _session} = Sessions.advance_to_actions(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Should be at actions
      assert html =~ "Action Items"

      # Click back
      html = render_click(view, "go_back")

      # Should now be at summary
      assert html =~ "Workshop Summary"
    end

    test "back button is shown in completed state and goes to summary", ctx do
      # Advance to completed
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)
      {:ok, session} = Sessions.advance_to_summary(session)
      {:ok, session} = Sessions.advance_to_actions(session)
      {:ok, _session} = Sessions.complete_session(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Should be at wrap-up (completed state)
      assert html =~ "Workshop Wrap-Up"

      # Back button should be visible
      assert html =~ "go_back"

      # Click back button - should go to summary
      html = view |> element("button", "Back") |> render_click()
      assert html =~ "Workshop Summary"
    end
  end

  describe "Facilitator timer functionality" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Timer Test",
          slug: "timer-test",
          version: "1.0.0",
          default_duration_minutes: 100
        })

      # Add 8 questions for a complete workshop
      for i <- 0..7 do
        {:ok, _} =
          Workshops.create_question(template, %{
            index: i,
            title: "Question #{i + 1}",
            criterion_number: "#{rem(i, 6) + 1}",
            criterion_name: "Criterion #{rem(i, 6) + 1}",
            explanation: "Explanation for question #{i + 1}",
            scale_type: if(i < 4, do: "balance", else: "maximal"),
            scale_min: if(i < 4, do: -5, else: 0),
            scale_max: if(i < 4, do: 5, else: 10),
            optimal_value: if(i < 4, do: 0, else: 10),
            discussion_prompts: []
          })
      end

      # Create session WITH planned duration
      {:ok, session} =
        Sessions.create_session(template, planned_duration_minutes: 100)

      # Create facilitator
      facilitator_token = Ecto.UUID.generate()

      {:ok, facilitator} =
        Sessions.join_session(session, "Facilitator", facilitator_token, is_facilitator: true)

      # Create regular participant
      participant_token = Ecto.UUID.generate()
      {:ok, participant} = Sessions.join_session(session, "Alice", participant_token)

      %{
        session: session,
        template: template,
        facilitator: facilitator,
        facilitator_token: facilitator_token,
        participant: participant,
        participant_token: participant_token
      }
    end

    test "timer is visible to facilitator during scoring phase", ctx do
      # Advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, _session} = Sessions.advance_to_scoring(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Timer should be visible with correct phase
      assert html =~ "facilitator-timer"
      assert html =~ "Time for this section"
      assert html =~ "Question 1"
    end

    test "timer is NOT visible to non-facilitator participant", ctx do
      # Advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, _session} = Sessions.advance_to_scoring(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.participant_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Timer should NOT be visible
      refute html =~ "facilitator-timer"
    end

    test "timer is NOT visible when session has no planned duration" do
      # Create a session without planned duration
      {:ok, template} =
        Workshops.create_template(%{
          name: "No Duration Test",
          slug: "no-duration-test",
          version: "1.0.0",
          default_duration_minutes: 100
        })

      {:ok, _} =
        Workshops.create_question(template, %{
          index: 0,
          title: "Q1",
          criterion_number: "1",
          criterion_name: "C1",
          explanation: "E1",
          scale_type: "balance",
          scale_min: -5,
          scale_max: 5,
          optimal_value: 0
        })

      # Create session WITHOUT planned_duration_minutes
      {:ok, session} = Sessions.create_session(template)

      facilitator_token = Ecto.UUID.generate()

      {:ok, _facilitator} =
        Sessions.join_session(session, "Facilitator", facilitator_token, is_facilitator: true)

      # Advance to scoring
      {:ok, session} = Sessions.start_session(session)
      {:ok, _session} = Sessions.advance_to_scoring(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{session.code}")

      # Timer should NOT be visible
      refute html =~ "facilitator-timer"
    end

    test "timer NOT visible during lobby phase", ctx do
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Timer should NOT be visible in lobby
      refute html =~ "facilitator-timer"
    end

    test "timer NOT visible during intro phase", ctx do
      {:ok, _session} = Sessions.start_session(ctx.session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Timer should NOT be visible in intro
      refute html =~ "facilitator-timer"
    end

    test "timer visible during summary phase", ctx do
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)
      {:ok, _session} = Sessions.advance_to_summary(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Timer should be visible with Summary + Actions phase
      assert html =~ "facilitator-timer"
      assert html =~ "Summary + Actions"
    end

    test "timer visible during actions phase with same phase name as summary", ctx do
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)
      {:ok, session} = Sessions.advance_to_summary(session)
      {:ok, _session} = Sessions.advance_to_actions(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Timer should be visible with Summary + Actions phase (shared with summary)
      assert html =~ "facilitator-timer"
      assert html =~ "Summary + Actions"
    end

    test "timer NOT visible in completed state", ctx do
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)
      {:ok, session} = Sessions.advance_to_summary(session)
      {:ok, session} = Sessions.advance_to_actions(session)
      {:ok, _session} = Sessions.complete_session(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Timer should NOT be visible in completed state
      refute html =~ "facilitator-timer"
    end

    test "timer displays correct segment duration (100 min / 10 = 10 min per segment)", ctx do
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, _session} = Sessions.advance_to_scoring(session)

      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Timer should show ~10 minutes (600 seconds, formatted as 10:00)
      # Note: there may be slight variations due to timing, so we check for 10: or 9:
      assert html =~ ~r/data-total="600"/
    end
  end

  describe "Turn-based scoring PubSub" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Turn Test",
          slug: "turn-pubsub-test-#{System.unique_integer()}",
          version: "1.0.0",
          default_duration_minutes: 100
        })

      # Add one question
      {:ok, _} =
        Workshops.create_question(template, %{
          index: 0,
          title: "Test Question",
          criterion_number: "1",
          criterion_name: "Test",
          explanation: "Test explanation",
          scale_type: "balance",
          scale_min: -5,
          scale_max: 5,
          optimal_value: 0,
          discussion_prompts: []
        })

      {:ok, session} = Sessions.create_session(template)

      # Create facilitator (joins first - will be first in turn order)
      facilitator_token = Ecto.UUID.generate()

      {:ok, facilitator} =
        Sessions.join_session(session, "Alice", facilitator_token, is_facilitator: true)

      # Small delay to ensure different joined_at
      Process.sleep(10)

      # Create regular participant (joins second - will be second in turn order)
      participant_token = Ecto.UUID.generate()
      {:ok, participant} = Sessions.join_session(session, "Bob", participant_token)

      %{
        session: session,
        template: template,
        facilitator: facilitator,
        facilitator_token: facilitator_token,
        participant: participant,
        participant_token: participant_token
      }
    end

    test "turn_advanced broadcast updates is_my_turn for next participant", ctx do
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Connect as Bob (the second participant)
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.participant_token)

      {:ok, view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Initially Alice is the current turn, so Bob should see waiting message
      assert html =~ "Waiting for"
      refute html =~ "Your turn to score"

      # Simulate Alice completing her turn - this updates DB and broadcasts
      {:ok, _updated_session} = Sessions.advance_turn(session)

      # Re-render and check - Bob should now see "Your turn to score"
      # because advance_turn broadcasts turn_advanced which the LiveView should receive
      html = render(view)
      assert html =~ "Your turn to score"
    end

    test "complete_turn via LiveView updates next participant's view", ctx do
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, _session} = Sessions.advance_to_scoring(session)

      # Connect as Alice (facilitator, first in turn order)
      alice_conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, alice_view, alice_html} = live(alice_conn, ~p"/session/#{ctx.session.code}")

      # Alice should see "Your turn to score"
      assert alice_html =~ "Your turn to score"

      # Connect as Bob (second participant)
      bob_conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.participant_token)

      {:ok, bob_view, bob_html} = live(bob_conn, ~p"/session/#{ctx.session.code}")

      # Bob should initially see waiting message
      assert bob_html =~ "Waiting for"
      refute bob_html =~ "Your turn to score"

      # Alice selects a score and places it
      alice_view
      |> element("button[phx-click='select_score'][phx-value-score='0']")
      |> render_click()

      alice_view |> element("button[phx-click='submit_score']") |> render_click()

      # Alice clicks "Done" to complete her turn
      alice_view |> element("button[phx-click='complete_turn']") |> render_click()

      # Bob should now see "Your turn to score" after receiving the broadcast
      bob_html = render(bob_view)
      assert bob_html =~ "Your turn to score"
      refute bob_html =~ "Waiting for"
    end

    test "current_turn_participant_id updates correctly after complete_turn", ctx do
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, _session} = Sessions.advance_to_scoring(session)

      # Verify initial turn order
      participants = Sessions.get_participants_in_turn_order(ctx.session)
      assert length(participants) == 2
      assert hd(participants).name == "Alice"
      assert Enum.at(participants, 1).name == "Bob"

      # Connect as Bob (second participant)
      bob_conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.participant_token)

      {:ok, bob_view, _bob_html} = live(bob_conn, ~p"/session/#{ctx.session.code}")

      # Verify Bob's participant is correct
      assert ctx.participant.name == "Bob"
      refute ctx.participant.is_observer

      # Connect as Alice and complete her turn
      alice_conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, alice_view, _} = live(alice_conn, ~p"/session/#{ctx.session.code}")

      alice_view
      |> element("button[phx-click='select_score'][phx-value-score='0']")
      |> render_click()

      alice_view |> element("button[phx-click='submit_score']") |> render_click()
      alice_view |> element("button[phx-click='complete_turn']") |> render_click()

      # Verify the session is updated in the database
      updated_session = Sessions.get_session!(ctx.session.id)
      assert updated_session.current_turn_index == 1

      # Verify current turn participant is Bob
      current_turn = Sessions.get_current_turn_participant(updated_session)
      assert current_turn.id == ctx.participant.id
      assert current_turn.name == "Bob"

      # Bob's view should show "Your turn to score"
      bob_html = render(bob_view)
      assert bob_html =~ "Your turn to score"
    end

    test "skip_turn via LiveView also updates next participant's view", ctx do
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # First, Alice completes her turn so Bob is the current turn
      alice_conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, alice_view, _} = live(alice_conn, ~p"/session/#{ctx.session.code}")

      # Alice scores and completes her turn
      alice_view
      |> element("button[phx-click='select_score'][phx-value-score='0']")
      |> render_click()

      alice_view |> element("button[phx-click='submit_score']") |> render_click()
      alice_view |> element("button[phx-click='complete_turn']") |> render_click()

      # Now it's Bob's turn
      # Add a third participant Charlie to verify skip works
      charlie_token = Ecto.UUID.generate()
      {:ok, _charlie} = Sessions.join_session(session, "Charlie", charlie_token)

      # Connect as Charlie (third participant)
      charlie_conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, charlie_token)

      {:ok, charlie_view, charlie_html} = live(charlie_conn, ~p"/session/#{ctx.session.code}")

      # Charlie should see "Waiting for Bob to score"
      assert charlie_html =~ "Waiting for"
      assert charlie_html =~ "Bob"
      refute charlie_html =~ "Your turn to score"

      # Re-render Alice's view and skip Bob
      _alice_html = render(alice_view)
      alice_view |> element("button[phx-click='skip_turn']") |> render_click()

      # Charlie should now see "Your turn to score" after receiving the broadcast
      charlie_html = render(charlie_view)
      assert charlie_html =~ "Your turn to score"
      refute charlie_html =~ "Waiting for"
    end

    test "skipped participant sees results view with Ready button (no second chance)", ctx do
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, _session} = Sessions.advance_to_scoring(session)

      # Connect as Alice (facilitator)
      alice_conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, alice_view, _} = live(alice_conn, ~p"/session/#{ctx.session.code}")

      # Connect as Bob (second participant)
      bob_conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.participant_token)

      {:ok, bob_view, _} = live(bob_conn, ~p"/session/#{ctx.session.code}")

      # Alice scores and completes her turn
      alice_view
      |> element("button[phx-click='select_score'][phx-value-score='0']")
      |> render_click()

      alice_view |> element("button[phx-click='submit_score']") |> render_click()
      alice_view |> element("button[phx-click='complete_turn']") |> render_click()

      # Now it's Bob's turn, but facilitator skips Bob
      _alice_html = render(alice_view)
      alice_view |> element("button[phx-click='skip_turn']") |> render_click()

      # All turns are now complete (Alice scored, Bob skipped)
      # Bob should see the results view with greyed-out Ready button
      bob_html = render(bob_view)

      # Should NOT see "Your turn to score" (no catch-up)
      refute bob_html =~ "Your turn to score"
      # Should see the greyed-out Ready button and skipped message
      assert bob_html =~ "Ready to Continue"
      assert bob_html =~ "You were skipped for this question"
      # Should NOT see the active "I'm Ready to Continue" button
      refute bob_html =~ "I'm Ready to Continue"
    end
  end

  describe "Require all participants ready before advancing" do
    setup do
      {:ok, template} =
        Workshops.create_template(%{
          name: "Ready Check Test",
          slug: "ready-check-test-#{System.unique_integer()}",
          version: "1.0.0",
          default_duration_minutes: 100
        })

      # Add two questions
      for i <- 0..1 do
        {:ok, _} =
          Workshops.create_question(template, %{
            index: i,
            title: "Question #{i + 1}",
            criterion_number: "#{i + 1}",
            criterion_name: "Criterion #{i + 1}",
            explanation: "Explanation #{i + 1}",
            scale_type: "balance",
            scale_min: -5,
            scale_max: 5,
            optimal_value: 0,
            discussion_prompts: []
          })
      end

      {:ok, session} = Sessions.create_session(template)

      # Create facilitator
      facilitator_token = Ecto.UUID.generate()

      {:ok, facilitator} =
        Sessions.join_session(session, "Facilitator", facilitator_token, is_facilitator: true)

      # Small delay
      Process.sleep(10)

      # Create two regular participants
      alice_token = Ecto.UUID.generate()
      {:ok, alice} = Sessions.join_session(session, "Alice", alice_token)

      Process.sleep(10)

      bob_token = Ecto.UUID.generate()
      {:ok, bob} = Sessions.join_session(session, "Bob", bob_token)

      %{
        session: session,
        template: template,
        facilitator: facilitator,
        facilitator_token: facilitator_token,
        alice: alice,
        alice_token: alice_token,
        bob: bob,
        bob_token: bob_token
      }
    end

    test "Next Question button is disabled when participants have scored but not clicked ready",
         ctx do
      # Start and advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Complete scoring for all participants
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, _} = Scoring.submit_score(session, ctx.alice, 0, 1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.alice, 0)
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, _} = Scoring.submit_score(session, ctx.bob, 0, 2)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.bob, 0)
      {:ok, _session} = Sessions.advance_turn(session)

      # Load as facilitator
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Scoring does NOT mean ready - button should be disabled
      # 0 of 2 participants ready (facilitator doesn't count)
      assert html =~ "0 of 2 participants ready"
      assert html =~ "bg-gray-600"
    end

    test "skipped participant counts as ready, but scored participant must click ready", ctx do
      # Start and advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Facilitator scores
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(session)

      # Alice scores
      {:ok, _} = Scoring.submit_score(session, ctx.alice, 0, 1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.alice, 0)
      {:ok, session} = Sessions.advance_turn(session)

      # Skip Bob (don't score, just advance)
      {:ok, _session} = Sessions.advance_turn(session)

      # Load as facilitator
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Bob skipped = auto-ready, Alice scored but NOT ready yet
      # 1 of 2 participants ready
      assert html =~ "1 of 2 participants ready"
      assert html =~ "bg-gray-600"
    end

    test "facilitator can advance when skipped participant and scored participant are both ready",
         ctx do
      # Start and advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Facilitator scores
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(session)

      # Alice scores
      {:ok, _} = Scoring.submit_score(session, ctx.alice, 0, 1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.alice, 0)
      {:ok, session} = Sessions.advance_turn(session)

      # Skip Bob (don't score, just advance)
      {:ok, _session} = Sessions.advance_turn(session)

      # Alice clicks Ready
      {:ok, _} = Sessions.set_participant_ready(ctx.alice, true)

      # Load as facilitator
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Bob skipped = auto-ready, Alice clicked Ready = all ready
      assert html =~ "All participants ready"
      assert html =~ "bg-green-600"
    end

    test "facilitator can skip via UI and advance when other participant clicks ready", ctx do
      # Start and advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Facilitator scores and completes turn
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(session)

      # Alice scores and completes turn
      {:ok, _} = Scoring.submit_score(session, ctx.alice, 0, 1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.alice, 0)
      {:ok, session} = Sessions.advance_turn(session)

      # Now it's Bob's turn - facilitator will skip via UI
      # Load as facilitator
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, view, html} = live(conn, ~p"/session/#{session.code}")

      # Should see skip button for Bob
      assert html =~ "Skip Bob"

      # Click skip button
      html = render_click(view, "skip_turn")

      # Now Bob is skipped, Alice needs to click Ready
      # Should show 1 of 2 ready (Bob auto-ready)
      assert html =~ "1 of 2 participants ready"

      # Alice clicks Ready (via backend since we're testing facilitator view)
      {:ok, _} = Sessions.set_participant_ready(ctx.alice, true)

      # Refresh the view to see updated state
      {:ok, _view, html} = live(conn, ~p"/session/#{session.code}")

      # Now all should be ready
      assert html =~ "All participants ready"
      assert html =~ "bg-green-600"
    end

    test "facilitator view updates via PubSub when participant clicks ready after skip", ctx do
      # Start and advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Facilitator scores and completes turn
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(session)

      # Alice scores and completes turn
      {:ok, _} = Scoring.submit_score(session, ctx.alice, 0, 1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.alice, 0)
      {:ok, session} = Sessions.advance_turn(session)

      # Skip Bob
      {:ok, _session} = Sessions.advance_turn(session)

      # Load facilitator view
      facilitator_conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, facilitator_view, html} = live(facilitator_conn, ~p"/session/#{ctx.session.code}")

      # Should show 1 of 2 ready (Bob skipped = auto-ready, Alice not ready)
      assert html =~ "1 of 2 participants ready"

      # Now Alice clicks Ready via her own view (triggers PubSub broadcast)
      alice_conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.alice_token)

      {:ok, alice_view, _html} = live(alice_conn, ~p"/session/#{ctx.session.code}")
      render_click(alice_view, "mark_ready")

      # Give PubSub a moment to propagate
      Process.sleep(50)

      # Re-render facilitator view to see the update
      html = render(facilitator_view)

      # Should now show all ready
      assert html =~ "All participants ready"
      assert html =~ "bg-green-600"
    end

    test "when only participant is skipped, facilitator can immediately advance", _ctx do
      # This tests the scenario with just facilitator + one participant
      # Create a fresh session with only facilitator and one participant
      {:ok, template} =
        Workshops.create_template(%{
          name: "Skip Only Test",
          slug: "skip-only-test-#{System.unique_integer()}",
          version: "1.0.0"
        })

      {:ok, _} =
        Workshops.create_question(template, %{
          index: 0,
          title: "Test Question",
          criterion_number: "1",
          criterion_name: "Test",
          explanation: "Test",
          scale_type: "balance",
          scale_min: -5,
          scale_max: 5,
          optimal_value: 0,
          discussion_prompts: []
        })

      {:ok, session} = Sessions.create_session(template)

      # Create facilitator
      facilitator_token = Ecto.UUID.generate()

      {:ok, facilitator} =
        Sessions.join_session(session, "Facilitator", facilitator_token, is_facilitator: true)

      Process.sleep(10)

      # Create just one regular participant
      bob_token = Ecto.UUID.generate()
      {:ok, _bob} = Sessions.join_session(session, "Bob", bob_token)

      # Start and advance to scoring
      {:ok, session} = Sessions.start_session(session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Facilitator scores and completes turn
      {:ok, _} = Scoring.submit_score(session, facilitator, 0, 0)
      {:ok, _} = Scoring.lock_participant_turn(session, facilitator, 0)
      {:ok, session} = Sessions.advance_turn(session)

      # Now it's Bob's turn - facilitator will skip via UI
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, facilitator_token)

      {:ok, view, html} = live(conn, ~p"/session/#{session.code}")

      # Should see skip button for Bob
      assert html =~ "Skip Bob"

      # Click skip button
      html = render_click(view, "skip_turn")

      # Bob is the only eligible participant and he's skipped = auto-ready
      # Should show all ready immediately
      assert html =~ "All participants ready"
      assert html =~ "bg-green-600"
    end

    test "Next Question button becomes enabled when all participants click ready", ctx do
      # Start and advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Complete scoring for all participants
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, _} = Scoring.submit_score(session, ctx.alice, 0, 1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.alice, 0)
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, _} = Scoring.submit_score(session, ctx.bob, 0, 2)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.bob, 0)
      {:ok, _session} = Sessions.advance_turn(session)

      # Now participants must explicitly click "I'm Ready to Continue"
      {:ok, _} = Sessions.set_participant_ready(ctx.alice, true)
      {:ok, _} = Sessions.set_participant_ready(ctx.bob, true)

      # Load as facilitator
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Should show all ready message now that both clicked ready
      assert html =~ "All participants ready"
      # Button should be enabled (green)
      assert html =~ "bg-green-600"
    end

    test "participants who scored are NOT automatically counted as ready", ctx do
      # Start and advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Complete scoring for all participants
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, _} = Scoring.submit_score(session, ctx.alice, 0, 1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.alice, 0)
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, _} = Scoring.submit_score(session, ctx.bob, 0, 2)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.bob, 0)
      {:ok, _session} = Sessions.advance_turn(session)

      # Load as facilitator
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Scoring does NOT mean ready - participants must click "I'm Ready to Continue"
      # 0 of 2 ready (Alice and Bob scored but haven't clicked ready)
      assert html =~ "0 of 2 participants ready"
      # Button should be disabled (gray)
      assert html =~ "bg-gray-600"
    end

    test "observer participants are not counted in readiness", ctx do
      # Add an observer
      observer_token = Ecto.UUID.generate()

      {:ok, _observer} =
        Sessions.join_session(ctx.session, "Observer", observer_token, is_observer: true)

      # Start and advance to scoring
      {:ok, session} = Sessions.start_session(ctx.session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      # Complete scoring for participating participants only
      {:ok, _} = Scoring.submit_score(session, ctx.facilitator, 0, 0)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.facilitator, 0)
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, _} = Scoring.submit_score(session, ctx.alice, 0, 1)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.alice, 0)
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, _} = Scoring.submit_score(session, ctx.bob, 0, 2)
      {:ok, _} = Scoring.lock_participant_turn(session, ctx.bob, 0)
      {:ok, _session} = Sessions.advance_turn(session)

      # Both non-observer participants mark ready
      {:ok, _} = Sessions.set_participant_ready(ctx.alice, true)
      {:ok, _} = Sessions.set_participant_ready(ctx.bob, true)

      # Load as facilitator
      conn =
        build_conn()
        |> Plug.Test.init_test_session(%{})
        |> put_session(:browser_token, ctx.facilitator_token)

      {:ok, _view, html} = live(conn, ~p"/session/#{ctx.session.code}")

      # Should show all ready (observer not counted)
      assert html =~ "All participants ready"
    end
  end
end
