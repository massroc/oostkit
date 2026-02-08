defmodule WorkgroupPulse.SessionsTest do
  use WorkgroupPulse.DataCase, async: true

  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulse.Sessions.{Participant, Session}
  alias WorkgroupPulse.Workshops.Template

  describe "sessions" do
    setup do
      template =
        Repo.insert!(%Template{
          name: "Test Workshop",
          slug: "session-test-#{System.unique_integer()}",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      %{template: template}
    end

    test "create_session/1 creates a session with generated code", %{template: template} do
      assert {:ok, %Session{} = session} = Sessions.create_session(template)
      assert session.code != nil
      assert String.length(session.code) >= 6
      assert session.state == "lobby"
      assert session.current_question_index == 0
      assert session.template_id == template.id
    end

    test "create_session/1 generates unique codes", %{template: template} do
      {:ok, session1} = Sessions.create_session(template)
      {:ok, session2} = Sessions.create_session(template)
      assert session1.code != session2.code
    end

    test "create_session/2 with custom settings", %{template: template} do
      settings = %{"skip_intro" => true, "timer_enabled" => false}

      assert {:ok, %Session{} = session} =
               Sessions.create_session(template, %{
                 planned_duration_minutes: 120,
                 settings: settings
               })

      assert session.planned_duration_minutes == 120
      assert session.settings == settings
    end

    test "get_session!/1 returns the session", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      assert Sessions.get_session!(session.id).id == session.id
    end

    test "get_session_by_code/1 returns the session", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      assert Sessions.get_session_by_code(session.code).id == session.id
    end

    test "get_session_by_code/1 returns nil for non-existent code" do
      assert Sessions.get_session_by_code("NONEXIST") == nil
    end

    test "get_session_by_code/1 is case-insensitive", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      assert Sessions.get_session_by_code(String.downcase(session.code)).id == session.id
      assert Sessions.get_session_by_code(String.upcase(session.code)).id == session.id
    end

    test "start_session/1 transitions from lobby to scoring", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      assert session.state == "lobby"

      {:ok, updated} = Sessions.start_session(session)
      assert updated.state == "scoring"
      assert updated.started_at != nil
      assert updated.current_question_index == 0
      assert updated.current_turn_index == 0
    end

    test "advance_question/1 increments question index", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      {:ok, session} = Sessions.start_session(session)

      {:ok, updated} = Sessions.advance_question(session)
      assert updated.current_question_index == 1
    end

    test "advance_to_summary/1 transitions to summary", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      {:ok, session} = Sessions.start_session(session)

      {:ok, updated} = Sessions.advance_to_summary(session)
      assert updated.state == "summary"
    end

    test "advance_to_completed/1 transitions to completed", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      {:ok, session} = Sessions.start_session(session)

      {:ok, session} = Sessions.advance_to_summary(session)

      {:ok, updated} = Sessions.advance_to_completed(session)
      assert updated.state == "completed"
      assert updated.completed_at != nil
    end

    test "touch_session/1 updates last_activity_at", %{template: template} do
      {:ok, session} = Sessions.create_session(template)

      # Set an older timestamp manually to test the update
      past_time = DateTime.add(DateTime.utc_now(), -60, :second) |> DateTime.truncate(:second)

      {:ok, session} =
        session
        |> Ecto.Changeset.change(last_activity_at: past_time)
        |> Repo.update()

      {:ok, updated} = Sessions.touch_session(session)
      assert DateTime.compare(updated.last_activity_at, past_time) == :gt
    end

    test "go_back_question/1 decrements question index", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      {:ok, session} = Sessions.start_session(session)

      {:ok, session} = Sessions.advance_question(session)
      assert session.current_question_index == 1

      {:ok, updated} = Sessions.go_back_question(session)
      assert updated.current_question_index == 0
    end

    test "go_back_question/1 returns error at first question", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      {:ok, session} = Sessions.start_session(session)

      assert session.current_question_index == 0

      assert {:error, :at_first_question} = Sessions.go_back_question(session)
    end

    test "go_back_to_scoring/2 transitions from summary to last question", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      {:ok, session} = Sessions.start_session(session)

      {:ok, session} = Sessions.advance_to_summary(session)
      assert session.state == "summary"

      {:ok, updated} = Sessions.go_back_to_scoring(session, 7)
      assert updated.state == "scoring"
      assert updated.current_question_index == 7
    end

    test "go_back_to_summary/1 transitions from completed to summary", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      {:ok, session} = Sessions.start_session(session)

      {:ok, session} = Sessions.advance_to_summary(session)
      {:ok, session} = Sessions.advance_to_completed(session)
      assert session.state == "completed"

      {:ok, updated} = Sessions.go_back_to_summary(session)
      assert updated.state == "summary"
    end

    test "get_session_with_participants/1 preloads participants", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      {:ok, _participant} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())

      result = Sessions.get_session_with_participants(session.id)
      assert length(result.participants) == 1
      assert hd(result.participants).name == "Alice"
    end
  end

  describe "participants" do
    setup do
      template =
        Repo.insert!(%Template{
          name: "Test Workshop",
          slug: "participant-test-#{System.unique_integer()}",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      {:ok, session} = Sessions.create_session(template)
      %{session: session}
    end

    test "join_session/3 creates a participant", %{session: session} do
      browser_token = Ecto.UUID.generate()

      assert {:ok, %Participant{} = participant} =
               Sessions.join_session(session, "Alice", browser_token)

      assert participant.name == "Alice"
      assert participant.browser_token == browser_token
      assert participant.status == "active"
      assert participant.is_ready == false
      assert participant.session_id == session.id
    end

    test "join_session/3 reuses existing participant with same browser_token", %{session: session} do
      browser_token = Ecto.UUID.generate()

      {:ok, p1} = Sessions.join_session(session, "Alice", browser_token)
      {:ok, p2} = Sessions.join_session(session, "Alice Updated", browser_token)

      assert p1.id == p2.id
      assert p2.name == "Alice Updated"
    end

    test "join_session/3 allows different participants with different tokens", %{session: session} do
      {:ok, p1} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      {:ok, p2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())

      assert p1.id != p2.id
    end

    test "join_session/3 rejects duplicate names", %{session: session} do
      {:ok, _p1} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      assert {:error, :name_taken} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
    end

    test "join_session/3 rejects duplicate names case-insensitively", %{session: session} do
      {:ok, _p1} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      assert {:error, :name_taken} = Sessions.join_session(session, "alice", Ecto.UUID.generate())
      assert {:error, :name_taken} = Sessions.join_session(session, "ALICE", Ecto.UUID.generate())
    end

    test "get_participant/2 finds participant by browser_token", %{session: session} do
      browser_token = Ecto.UUID.generate()
      {:ok, participant} = Sessions.join_session(session, "Alice", browser_token)

      assert Sessions.get_participant(session, browser_token).id == participant.id
    end

    test "get_participant/2 returns nil for non-existent token", %{session: session} do
      assert Sessions.get_participant(session, Ecto.UUID.generate()) == nil
    end

    test "list_participants/1 returns all participants", %{session: session} do
      {:ok, _p1} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      {:ok, _p2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())

      participants = Sessions.list_participants(session)
      assert length(participants) == 2
    end

    test "list_active_participants/1 returns only active participants", %{session: session} do
      {:ok, p1} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      {:ok, _p2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())

      {:ok, _} = Sessions.update_participant_status(p1, "inactive")

      active = Sessions.list_active_participants(session)
      assert length(active) == 1
      assert hd(active).name == "Bob"
    end

    test "update_participant_status/2 changes status", %{session: session} do
      {:ok, participant} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())

      {:ok, updated} = Sessions.update_participant_status(participant, "inactive")
      assert updated.status == "inactive"
    end

    test "set_participant_ready/2 sets ready state", %{session: session} do
      {:ok, participant} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      assert participant.is_ready == false

      {:ok, updated} = Sessions.set_participant_ready(participant, true)
      assert updated.is_ready == true
    end

    test "reset_all_ready/1 resets all participants' ready state", %{session: session} do
      {:ok, p1} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      {:ok, p2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())

      {:ok, _} = Sessions.set_participant_ready(p1, true)
      {:ok, _} = Sessions.set_participant_ready(p2, true)

      :ok = Sessions.reset_all_ready(session)

      participants = Sessions.list_participants(session)
      assert Enum.all?(participants, fn p -> p.is_ready == false end)
    end

    test "all_participants_ready?/1 checks if all active participants are ready", %{
      session: session
    } do
      {:ok, p1} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      {:ok, p2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())

      refute Sessions.all_participants_ready?(session)

      {:ok, _} = Sessions.set_participant_ready(p1, true)
      refute Sessions.all_participants_ready?(session)

      {:ok, _} = Sessions.set_participant_ready(p2, true)
      assert Sessions.all_participants_ready?(session)
    end

    test "count_participants/1 returns participant count", %{session: session} do
      assert Sessions.count_participants(session) == 0

      {:ok, _} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      {:ok, _} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())

      assert Sessions.count_participants(session) == 2
    end
  end

  describe "session code generation" do
    test "generate_code/0 creates alphanumeric codes" do
      code = Sessions.generate_code()
      assert String.length(code) >= 6
      assert code =~ ~r/^[A-Z0-9]+$/
    end

    test "generate_code/0 creates unique codes" do
      codes = for _ <- 1..100, do: Sessions.generate_code()
      unique_codes = Enum.uniq(codes)
      assert length(unique_codes) == 100
    end
  end

  describe "turn-based scoring" do
    setup do
      template =
        Repo.insert!(%Template{
          name: "Test Workshop",
          slug: "turn-test-#{System.unique_integer()}",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      {:ok, session} = Sessions.create_session(template)
      {:ok, session} = Sessions.start_session(session)

      # Create participants in specific order
      {:ok, alice} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      # Small delay to ensure different joined_at timestamps
      Process.sleep(10)
      {:ok, bob} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())
      Process.sleep(10)
      {:ok, charlie} = Sessions.join_session(session, "Charlie", Ecto.UUID.generate())

      %{session: session, alice: alice, bob: bob, charlie: charlie}
    end

    test "get_participants_in_turn_order returns participants by join time", ctx do
      participants = Sessions.get_participants_in_turn_order(ctx.session)

      assert length(participants) == 3
      assert Enum.at(participants, 0).id == ctx.alice.id
      assert Enum.at(participants, 1).id == ctx.bob.id
      assert Enum.at(participants, 2).id == ctx.charlie.id
    end

    test "get_current_turn_participant returns first participant initially", ctx do
      current = Sessions.get_current_turn_participant(ctx.session)
      assert current.id == ctx.alice.id
    end

    test "advance_turn moves to next participant", ctx do
      # Alice is first
      assert Sessions.get_current_turn_participant(ctx.session).id == ctx.alice.id

      # Advance turn - Bob should be next
      {:ok, updated_session} = Sessions.advance_turn(ctx.session)
      assert updated_session.current_turn_index == 1
      assert Sessions.get_current_turn_participant(updated_session).id == ctx.bob.id

      # Advance again - Charlie should be next
      {:ok, updated_session} = Sessions.advance_turn(updated_session)
      assert updated_session.current_turn_index == 2
      assert Sessions.get_current_turn_participant(updated_session).id == ctx.charlie.id
    end

    test "advance_turn marks all turns complete when all have had a turn", ctx do
      session = ctx.session

      # Advance through all participants without anyone scoring
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, session} = Sessions.advance_turn(session)
      {:ok, session} = Sessions.advance_turn(session)

      # Should mark all turns complete
      # current_turn_index should be past the last participant
      assert session.current_turn_index == 3
      assert Sessions.all_turns_complete?(session) == true
      # No current turn participant since all turns are done
      assert Sessions.get_current_turn_participant(session) == nil
    end

    test "skip_turn advances to next participant", ctx do
      {:ok, updated_session} = Sessions.skip_turn(ctx.session)
      assert updated_session.current_turn_index == 1
      assert Sessions.get_current_turn_participant(updated_session).id == ctx.bob.id
    end

    test "participants_turn? returns true only for current turn", ctx do
      assert Sessions.participants_turn?(ctx.session, ctx.alice) == true
      assert Sessions.participants_turn?(ctx.session, ctx.bob) == false
      assert Sessions.participants_turn?(ctx.session, ctx.charlie) == false

      {:ok, updated_session} = Sessions.advance_turn(ctx.session)
      assert Sessions.participants_turn?(updated_session, ctx.alice) == false
      assert Sessions.participants_turn?(updated_session, ctx.bob) == true
      assert Sessions.participants_turn?(updated_session, ctx.charlie) == false
    end
  end
end
