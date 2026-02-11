defmodule WorkgroupPulse.NotesTest do
  use WorkgroupPulse.DataCase, async: true

  alias WorkgroupPulse.Notes
  alias WorkgroupPulse.Notes.{Action, Note}
  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulse.Workshops.Template

  describe "notes" do
    setup do
      template =
        Repo.insert!(%Template{
          name: "Notes Test Workshop",
          slug: "notes-test-#{System.unique_integer()}",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      {:ok, session} = Sessions.create_session(template)
      %{session: session}
    end

    test "create_note/2 creates a note", %{session: session} do
      assert {:ok, %Note{} = note} =
               Notes.create_note(session, %{content: "Important discussion point"})

      assert note.content == "Important discussion point"
      assert note.session_id == session.id
    end

    test "create_note/2 requires content", %{session: session} do
      assert {:error, changeset} = Notes.create_note(session, %{})
      assert "can't be blank" in errors_on(changeset).content
    end

    test "list_all_notes/1 returns all session notes in order", %{session: session} do
      {:ok, _} = Notes.create_note(session, %{content: "First"})
      {:ok, _} = Notes.create_note(session, %{content: "Second"})
      {:ok, _} = Notes.create_note(session, %{content: "Third"})

      notes = Notes.list_all_notes(session)
      assert length(notes) == 3
      assert Enum.map(notes, & &1.content) == ["First", "Second", "Third"]
    end

    test "update_note/2 updates content", %{session: session} do
      {:ok, note} = Notes.create_note(session, %{content: "Original"})

      {:ok, updated} = Notes.update_note(note, %{content: "Updated content"})
      assert updated.content == "Updated content"
    end

    test "delete_note/1 removes the note", %{session: session} do
      {:ok, note} = Notes.create_note(session, %{content: "To delete"})

      assert {:ok, _} = Notes.delete_note(note)
      assert Notes.list_all_notes(session) == []
    end
  end

  describe "actions" do
    setup do
      template =
        Repo.insert!(%Template{
          name: "Actions Test Workshop",
          slug: "actions-test-#{System.unique_integer()}",
          version: "1.0.0",
          default_duration_minutes: 180
        })

      {:ok, session} = Sessions.create_session(template)
      %{session: session}
    end

    test "create_action/2 creates a session action", %{session: session} do
      assert {:ok, %Action{} = action} =
               Notes.create_action(session, %{
                 description: "Follow up on elbow room concerns"
               })

      assert action.description == "Follow up on elbow room concerns"
      assert action.completed == false
      assert action.session_id == session.id
    end

    test "create_action/2 requires description", %{session: session} do
      assert {:error, changeset} = Notes.create_action(session, %{})
      assert "can't be blank" in errors_on(changeset).description
    end

    test "list_all_actions/1 returns all session actions in order", %{session: session} do
      {:ok, _} = Notes.create_action(session, %{description: "First"})
      {:ok, _} = Notes.create_action(session, %{description: "Second"})
      {:ok, _} = Notes.create_action(session, %{description: "Third"})

      actions = Notes.list_all_actions(session)
      assert length(actions) == 3
      assert Enum.map(actions, & &1.description) == ["First", "Second", "Third"]
    end

    test "update_action/2 updates description", %{session: session} do
      {:ok, action} = Notes.create_action(session, %{description: "Original"})

      {:ok, updated} = Notes.update_action(action, %{description: "Updated"})
      assert updated.description == "Updated"
    end

    test "complete_action/1 marks action as completed", %{session: session} do
      {:ok, action} = Notes.create_action(session, %{description: "To complete"})
      assert action.completed == false

      {:ok, completed} = Notes.complete_action(action)
      assert completed.completed == true
    end

    test "uncomplete_action/1 marks action as not completed", %{session: session} do
      {:ok, action} = Notes.create_action(session, %{description: "To toggle"})
      {:ok, action} = Notes.complete_action(action)
      assert action.completed == true

      {:ok, uncompleted} = Notes.uncomplete_action(action)
      assert uncompleted.completed == false
    end

    test "delete_action/1 removes the action", %{session: session} do
      {:ok, action} = Notes.create_action(session, %{description: "To delete"})

      assert {:ok, _} = Notes.delete_action(action)
      assert Notes.list_all_actions(session) == []
    end
  end
end
