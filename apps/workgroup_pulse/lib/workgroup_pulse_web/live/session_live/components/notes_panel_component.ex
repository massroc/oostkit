defmodule WorkgroupPulseWeb.SessionLive.Components.NotesPanelComponent do
  @moduledoc """
  Renders the notes/actions side panel fixed to the right edge of the viewport.
  Includes collapsed tab (vertical "Notes" text) and expanded panel.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]

  attr :notes_revealed, :boolean, required: true
  attr :carousel_index, :integer, required: true
  attr :question_notes, :list, required: true
  attr :note_input, :string, required: true
  attr :all_actions, :list, required: true
  attr :action_count, :integer, required: true
  attr :action_input, :string, required: true

  def render(assigns) do
    ~H"""
    <%= if @notes_revealed do %>
      <div class="fixed top-[52px] left-0 right-0 bottom-0 z-10" phx-click="hide_notes"></div>
      <div class="fixed top-[52px] right-0 bottom-0 w-[480px] z-20 py-6 pr-4">
        {render_notes_content(assigns)}
      </div>
    <% else %>
      <%= if @carousel_index == 4 do %>
        <button
          phx-click="reveal_notes"
          class="fixed top-[52px] right-0 bottom-0 w-[40px] z-20 py-6 cursor-pointer group"
        >
          <.sheet
            variant={:secondary}
            class="h-full w-full flex items-center justify-center shadow-sheet"
            style="transform: rotate(0deg)"
          >
            <span class="font-workshop text-sm font-bold text-ink-blue/60 group-hover:text-ink-blue writing-vertical-rl">
              Notes
            </span>
          </.sheet>
        </button>
      <% end %>
    <% end %>
    """
  end

  defp render_notes_content(assigns) do
    ~H"""
    <.sheet
      variant={:secondary}
      class="notes-panel p-4 w-full h-full shadow-sheet"
      style="transform: rotate(0deg)"
    >
      <!-- Notes section -->
      <div class="mb-6">
        <div class="mb-2">
          <div class="font-workshop text-lg font-bold text-ink-blue underline underline-offset-[3px] decoration-[1.5px] decoration-ink-blue/20 opacity-85">
            Notes
            <%= if length(@question_notes) > 0 do %>
              <span class="text-sm font-normal text-ink-blue/50 ml-1">
                ({length(@question_notes)})
              </span>
            <% end %>
          </div>
        </div>

        <form phx-submit="add_note" class="mb-2">
          <input
            type="text"
            name="note"
            value={@note_input}
            phx-change="update_note_input"
            phx-debounce="300"
            placeholder="Add a note..."
            class="w-full bg-surface-sheet border border-ink-blue/10 rounded-lg px-3 py-2 text-sm text-ink-blue placeholder-ink-blue/40 focus:outline-none focus:border-accent-purple focus:ring-1 focus:ring-accent-purple font-workshop"
          />
        </form>

        <div class="space-y-1.5">
          <%= if length(@question_notes) > 0 do %>
            <%= for note <- @question_notes do %>
              <div class="bg-surface-sheet/50 rounded p-2 text-sm group">
                <div class="flex justify-between items-start gap-1">
                  <p class="font-workshop text-ink-blue flex-1">{note.content}</p>
                  <button
                    type="button"
                    phx-click="delete_note"
                    phx-value-id={note.id}
                    class="text-ink-blue/30 hover:text-traffic-red transition-colors opacity-0 group-hover:opacity-100 shrink-0"
                  >
                    ✕
                  </button>
                </div>
              </div>
            <% end %>
          <% else %>
            <p class="text-ink-blue/50 text-sm italic font-workshop">
              No notes yet. Type above to add one.
            </p>
          <% end %>
        </div>
      </div>
      <!-- Actions section -->
      <div class="border-t border-ink-blue/10 pt-4">
        <div class="mb-2">
          <div class="font-workshop text-lg font-bold text-ink-blue underline underline-offset-[3px] decoration-[1.5px] decoration-ink-blue/20 opacity-85">
            Actions
            <%= if @action_count > 0 do %>
              <span class="text-sm font-normal text-ink-blue/50 ml-1">
                ({@action_count})
              </span>
            <% end %>
          </div>
        </div>

        <form phx-submit="add_action" class="mb-2">
          <input
            type="text"
            name="action"
            value={@action_input}
            phx-change="update_action_input"
            phx-debounce="300"
            placeholder="Add an action..."
            class="w-full bg-surface-sheet border border-ink-blue/10 rounded-lg px-3 py-2 text-sm text-ink-blue placeholder-ink-blue/40 focus:outline-none focus:border-accent-purple focus:ring-1 focus:ring-accent-purple font-workshop"
          />
        </form>

        <div class="space-y-1.5">
          <%= if @action_count > 0 do %>
            <%= for action <- @all_actions do %>
              <div class="bg-surface-sheet/50 rounded p-2 text-sm group">
                <div class="flex justify-between items-start gap-1">
                  <p class="font-workshop text-ink-blue flex-1">{action.description}</p>
                  <button
                    type="button"
                    phx-click="delete_action"
                    phx-value-id={action.id}
                    class="text-ink-blue/30 hover:text-traffic-red transition-colors opacity-0 group-hover:opacity-100 shrink-0"
                  >
                    ✕
                  </button>
                </div>
              </div>
            <% end %>
          <% else %>
            <p class="text-ink-blue/50 text-sm italic font-workshop">
              No actions yet. Type above to add one.
            </p>
          <% end %>
        </div>
      </div>
    </.sheet>
    """
  end
end
