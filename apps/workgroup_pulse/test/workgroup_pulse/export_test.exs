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
        Notes.create_note(session, %{content: "This is a test note"})

      # Add an action
      {:ok, _action} =
        Notes.create_action(session, %{description: "Follow up on feedback"})

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
      assert data =~ "NOTES\nNote"
      assert data =~ "ACTION ITEMS\nAction"
    end

    test "exports team report as CSV", %{session: session} do
      {:ok, {filename, content_type, data}} =
        Export.export(session, content: :team)

      assert filename == "workshop_#{session.code}_team_report.csv"
      assert content_type == "text/csv"
      assert data =~ "SESSION INFORMATION"
      assert data =~ session.code
      assert data =~ "TEAM SCORES"
      # Team report header with disclaimer
      assert data =~ "TEAM REPORT\nNo individual scores, names or notes"
      # Team report should NOT include participants, individual scores, or notes
      refute data =~ "PARTICIPANTS"
      refute data =~ "INDIVIDUAL SCORES"
      refute data =~ "NOTES"
      assert data =~ "ACTION ITEMS\nAction"
      # Team report includes strengths/concerns
      assert data =~ "STRENGTHS"
      assert data =~ "AREAS OF CONCERN"
    end

    test "team report excludes identifying information", %{session: session} do
      {:ok, {_filename, _content_type, data}} =
        Export.export(session, content: :team)

      # No participants, individual scores, or notes in team report
      refute data =~ "PARTICIPANTS"
      refute data =~ "NOTES"
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
        Notes.create_note(session, %{
          content: "Note with \"quotes\" and, commas"
        })

      {:ok, {_filename, _content_type, data}} =
        Export.export(session, content: :full)

      # CSV escaping should wrap in quotes and escape internal quotes
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
