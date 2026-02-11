defmodule WorkgroupPulseWeb.SessionLive.Handlers.ContentHandlers do
  @moduledoc """
  Handlers for content events: notes, actions, export, and UI toggles.
  """

  import Phoenix.Component, only: [assign: 2, assign: 3]
  import Phoenix.LiveView, only: [push_event: 3, put_flash: 3]

  alias WorkgroupPulse.Export
  alias WorkgroupPulse.Notes
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulseWeb.SessionLive.Helpers.DataLoaders

  # UI toggle events

  def handle_show_criterion_info(socket, question_index) do
    {:noreply, assign(socket, show_criterion_popup: question_index)}
  end

  def handle_close_criterion_info(socket) do
    {:noreply, assign(socket, show_criterion_popup: nil)}
  end

  def handle_focus_sheet(socket, :main) do
    {:noreply, assign(socket, carousel_index: 4)}
  end

  def handle_focus_sheet(socket, :notes) do
    {:noreply, assign(socket, notes_revealed: true)}
  end

  def handle_reveal_notes(socket) do
    {:noreply, assign(socket, notes_revealed: true)}
  end

  def handle_hide_notes(socket) do
    {:noreply, assign(socket, notes_revealed: false)}
  end

  @doc """
  Handles dismiss for any prompt type (discuss, team_discuss).
  """
  def handle_dismiss_prompt(socket, type) do
    {:noreply, assign(socket, type, false)}
  end

  # Note events

  def handle_update_note_input(socket, value) do
    {:noreply, assign(socket, note_input: value)}
  end

  def handle_add_note(socket) do
    content = String.trim(socket.assigns.note_input)

    if content == "" do
      {:noreply, socket}
    else
      session = socket.assigns.session
      participant = socket.assigns.participant
      question_index = session.current_question_index

      attrs = %{content: content, author_name: participant.name}

      case Notes.create_note(session, question_index, attrs) do
        {:ok, _note} ->
          broadcast(session, {:note_updated, question_index})

          {:noreply,
           socket
           |> assign(note_input: "")
           |> DataLoaders.load_notes(session, question_index)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add note")}
      end
    end
  end

  def handle_delete_note(socket, note_id) do
    session = socket.assigns.session
    question_index = session.current_question_index
    note_id_int = String.to_integer(note_id)

    note = Enum.find(socket.assigns.question_notes, &(&1.id == note_id_int))

    if note do
      case Notes.delete_note(note) do
        {:ok, _} ->
          broadcast(session, {:note_updated, question_index})
          {:noreply, DataLoaders.load_notes(socket, session, question_index)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete note")}
      end
    else
      {:noreply, socket}
    end
  end

  # Action events

  def handle_update_action_input(socket, value) do
    {:noreply, assign(socket, action_input: value)}
  end

  def handle_add_action(socket) do
    description = String.trim(socket.assigns.action_input)

    if description == "" do
      {:noreply, socket}
    else
      session = socket.assigns.session

      attrs = %{description: description, owner_name: ""}

      case Notes.create_action(session, attrs) do
        {:ok, action} ->
          broadcast(session, {:action_updated, action.id})

          {:noreply,
           socket
           |> assign(action_input: "")
           |> DataLoaders.load_actions_data(session)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add action")}
      end
    end
  end

  def handle_delete_action(socket, action_id) do
    session = socket.assigns.session
    action_id_int = String.to_integer(action_id)
    action = Enum.find(socket.assigns.all_actions, &(&1.id == action_id_int))

    if action do
      case Notes.delete_action(action) do
        {:ok, _} ->
          broadcast(session, {:action_updated, action_id})
          {:noreply, DataLoaders.load_actions_data(socket, session)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete action")}
      end
    else
      {:noreply, socket}
    end
  end

  # Export events

  def handle_toggle_export_modal(socket) do
    {:noreply, assign(socket, show_export_modal: !socket.assigns.show_export_modal)}
  end

  def handle_close_export_modal(socket) do
    {:noreply, assign(socket, show_export_modal: false)}
  end

  def handle_select_export_report_type(socket, type) do
    {:noreply, assign(socket, export_report_type: type)}
  end

  def handle_export(socket, "pdf") do
    report_type = socket.assigns.export_report_type
    code = socket.assigns.session.code
    filename = "workshop_#{code}_#{report_type}_report.pdf"

    {:noreply,
     socket
     |> assign(show_export_modal: false)
     |> push_event("generate_pdf", %{report_type: report_type, filename: filename})}
  end

  def handle_export(socket, "csv") do
    session = socket.assigns.session
    report_type = socket.assigns.export_report_type
    content_atom = String.to_existing_atom(report_type)

    {:ok, {filename, content_type, data}} = Export.export(session, content: content_atom)

    {:noreply,
     socket
     |> assign(show_export_modal: false)
     |> push_event("download", %{filename: filename, content_type: content_type, data: data})}
  end

  # Private helpers

  defp broadcast(session, event) do
    Phoenix.PubSub.broadcast(
      WorkgroupPulse.PubSub,
      Sessions.session_topic(session),
      event
    )
  end
end
