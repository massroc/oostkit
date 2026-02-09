defmodule WorkgroupPulse.ExportTest do
  use WorkgroupPulse.DataCase, async: true

  alias WorkgroupPulse.Export
  alias WorkgroupPulse.Notes
  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Scoring
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulse.Workshops.{Question, Template}

  describe "export/2" do
    setup do
      slug = "export-test-#{System.unique_integer([:positive])}"

      template =
        Repo.insert!(%Template{
          name: "Export Test Workshop",
          slug: slug,
          version: "1.0.0",
          default_duration_minutes: 120
        })

      # Create two questions
      Repo.insert!(%Question{
        template_id: template.id,
        index: 0,
        title: "Elbow Room",
        criterion_number: "1",
        criterion_name: "Autonomy",
        explanation: "Test explanation",
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        optimal_value: 0
      })

      Repo.insert!(%Question{
        template_id: template.id,
        index: 1,
        title: "Mutual Support",
        criterion_number: "4",
        criterion_name: "Support",
        explanation: "Test explanation",
        scale_type: "maximal",
        scale_min: 0,
        scale_max: 10,
        optimal_value: nil
      })

      {:ok, session} = Sessions.create_session(template)
      {:ok, participant1} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      {:ok, participant2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())

      # Submit scores
      Scoring.submit_score(session, participant1, 0, 1)
      Scoring.submit_score(session, participant2, 0, -1)
      Scoring.submit_score(session, participant1, 1, 8)
      Scoring.submit_score(session, participant2, 1, 6)

      # Add a note
      {:ok, _note} =
        Notes.create_note(session, 0, %{
          content: "This is a test note",
          author_name: "Alice"
        })

      # Add an action
      {:ok, _action} =
        Notes.create_action(session, %{
          description: "Follow up on feedback",
          owner_name: "Alice"
        })

      %{session: session, template: template}
    end

    test "exports full report as CSV", %{session: session} do
      {:ok, {filename, content_type, data}} =
        Export.export(session, content: :full)

      assert filename == "workshop_#{session.code}_full_report.csv"
      assert content_type == "text/csv"
      assert data =~ "SESSION INFORMATION"
      assert data =~ session.code
      assert data =~ "PARTICIPANTS"
      assert data =~ "Alice"
      assert data =~ "Bob"
      assert data =~ "TEAM SCORES"
      assert data =~ "INDIVIDUAL SCORES"
      assert data =~ "Elbow Room"
      assert data =~ "Mutual Support"
      assert data =~ "NOTES"
      assert data =~ "This is a test note"
      assert data =~ "ACTION ITEMS"
      assert data =~ "Follow up on feedback"
      # Full report includes author and owner columns
      assert data =~ "Question,Note,Author"
      assert data =~ "Action,Owner,Created"
    end

    test "exports team report as CSV", %{session: session} do
      {:ok, {filename, content_type, data}} =
        Export.export(session, content: :team)

      assert filename == "workshop_#{session.code}_team_report.csv"
      assert content_type == "text/csv"
      assert data =~ "SESSION INFORMATION"
      assert data =~ session.code
      assert data =~ "TEAM SCORES"
      # Team report should NOT include participants or individual scores
      refute data =~ "PARTICIPANTS"
      refute data =~ "INDIVIDUAL SCORES"
      # Team report notes have no Author column
      assert data =~ "Question,Note\n"
      # Team report actions have no Owner column
      assert data =~ "Action,Created\n"
      # Team report includes strengths/concerns
      assert data =~ "STRENGTHS"
      assert data =~ "AREAS OF CONCERN"
    end

    test "team report excludes identifying information", %{session: session} do
      {:ok, {_filename, _content_type, data}} =
        Export.export(session, content: :team)

      # Split into sections to check notes and actions sections specifically
      # The note content should appear but not the author name in that context
      lines = String.split(data, "\n")

      # Find the NOTES section lines
      notes_start = Enum.find_index(lines, &(&1 == "NOTES"))
      actions_start = Enum.find_index(lines, &(&1 == "ACTION ITEMS"))

      # Notes section header should not have Author column
      notes_header = Enum.at(lines, notes_start + 1)
      assert notes_header == "Question,Note"

      # Actions section header should not have Owner column
      actions_header = Enum.at(lines, actions_start + 1)
      assert actions_header == "Action,Created"

      # Participant names should not appear anywhere in team report
      # (except in the note content itself if a name happens to be in the text)
      refute data =~ "PARTICIPANTS"
    end

    test "defaults to full report", %{session: session} do
      {:ok, {filename, _content_type, data}} = Export.export(session)

      assert filename == "workshop_#{session.code}_full_report.csv"
      assert data =~ "PARTICIPANTS"
      assert data =~ "INDIVIDUAL SCORES"
    end

    test "handles empty notes gracefully", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      {:ok, _participant} = Sessions.join_session(session, "Charlie", Ecto.UUID.generate())

      {:ok, {_filename, _content_type, data}} =
        Export.export(session, content: :full)

      assert data =~ "No notes recorded"
    end

    test "handles empty actions gracefully", %{template: template} do
      {:ok, session} = Sessions.create_session(template)
      {:ok, _participant} = Sessions.join_session(session, "Charlie", Ecto.UUID.generate())

      {:ok, {_filename, _content_type, data}} =
        Export.export(session, content: :full)

      assert data =~ "No action items recorded"
    end

    test "escapes CSV special characters", %{session: session} do
      {:ok, _participant} = Sessions.join_session(session, "Test, User", Ecto.UUID.generate())

      {:ok, _note} =
        Notes.create_note(session, 0, %{
          content: "Note with \"quotes\" and, commas",
          author_name: "Test, User"
        })

      {:ok, {_filename, _content_type, data}} =
        Export.export(session, content: :full)

      # CSV escaping should wrap in quotes and escape internal quotes
      assert data =~ "\"Test, User\""
      assert data =~ "\"Note with \"\"quotes\"\" and, commas\""
    end

    test "formats balance scores with + prefix for positive values", %{session: session} do
      {:ok, {_filename, _content_type, data}} =
        Export.export(session, content: :full)

      # Alice scored +1 on Elbow Room (balance scale)
      assert data =~ "+1"
    end
  end
end
