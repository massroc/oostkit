defmodule ProductiveWorkgroupsWeb.SessionLive.ScoreResultsComponent do
  @moduledoc """
  LiveComponent for displaying score results and notes capture.
  Isolates re-renders to just this section when scores change.

  Note: Facilitator tips (discussion prompts) are displayed on the question card
  during the scoring phase, not on this results component.
  """
  use ProductiveWorkgroupsWeb, :live_component

  import ProductiveWorkgroupsWeb.SessionLive.ScoreHelpers,
    only: [text_color_class: 1, bg_color_class: 1]

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  # All events are handled by parent LiveView for test compatibility
  # This component is purely for render isolation

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Results summary with team discussion prompt -->
      <div class="bg-gray-800 rounded-lg p-6">
        <!-- Team discussion prompt - at top, matching individual turn prompts -->
        <div class="text-center mb-4">
          <div class="text-green-400 text-lg font-semibold">
            Discuss as a team
          </div>
          <p class="text-gray-400 text-sm mt-1">
            Look for variance across the group
          </p>
        </div>
        <!-- Individual scores - horizontal boxes -->
        <div class="flex flex-wrap gap-2 justify-center">
          <%= for score <- @all_scores do %>
            <div
              class={[
                "rounded-lg p-2 text-center min-w-[4rem] flex-shrink-0",
                bg_color_class(score.color)
              ]}
              title={score.participant_name}
            >
              <div class={["text-xl font-bold", text_color_class(score.color)]}>
                <%= if @current_question.scale_type == "balance" and score.value > 0 do %>
                  +
                <% end %>
                {score.value}
              </div>
              <div class="text-xs text-gray-400 truncate max-w-[4rem]">{score.participant_name}</div>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Toggle button for notes - events go to parent -->
      <div>
        <button
          type="button"
          phx-click="toggle_notes"
          class={[
            "w-full px-4 py-3 rounded-lg font-medium transition-colors flex items-center justify-center gap-2",
            if(@show_notes,
              do: "bg-blue-600 text-white",
              else: "bg-gray-700 text-gray-300 hover:bg-gray-600"
            )
          ]}
        >
          <span>{if @show_notes, do: "Hide", else: "Add"} Notes</span>
          <%= if length(@question_notes) > 0 do %>
            <span class="bg-gray-600 text-white text-xs px-2 py-0.5 rounded-full">
              {length(@question_notes)}
            </span>
          <% end %>
        </button>
      </div>
      
    <!-- Notes capture (collapsible) -->
      <%= if @show_notes do %>
        <div class="bg-gray-800 rounded-lg p-6 border border-blue-600/50">
          <!-- Existing notes -->
          <%= if length(@question_notes) > 0 do %>
            <ul class="space-y-3 mb-4">
              <%= for note <- @question_notes do %>
                <li class="bg-gray-700 rounded-lg p-3">
                  <div class="flex justify-between items-start gap-2">
                    <p class="text-gray-300 flex-1">{note.content}</p>
                    <button
                      type="button"
                      phx-click="delete_note"
                      phx-value-id={note.id}
                      class="text-gray-500 hover:text-red-400 transition-colors text-sm"
                      title="Delete note"
                    >
                      ✕
                    </button>
                  </div>
                  <p class="text-xs text-gray-500 mt-1">— {note.author_name}</p>
                </li>
              <% end %>
            </ul>
          <% end %>
          
    <!-- Add note form - events go to parent LiveView for test compatibility -->
          <form phx-submit="add_note" class="flex gap-2">
            <input
              type="text"
              name="note"
              value={@note_input}
              phx-change="update_note_input"
              phx-debounce="300"
              placeholder="Capture a key discussion point..."
              class="flex-1 bg-gray-700 border border-gray-600 rounded-lg px-4 py-2 text-white placeholder-gray-400 focus:outline-none focus:border-blue-500"
            />
            <button
              type="submit"
              class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors"
            >
              Add
            </button>
          </form>
          <p class="text-xs text-gray-500 mt-2">
            Notes are visible to all participants and saved with the session.
          </p>
        </div>
      <% end %>
      
    <!-- Ready / Next controls -->
      <div class="bg-gray-800 rounded-lg p-6">
        <%= if @participant.is_facilitator do %>
          <div class="flex gap-3">
            <button
              phx-click="go_back"
              class="px-6 py-3 bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-white font-medium rounded-lg transition-colors flex items-center gap-2"
            >
              <span>←</span>
              <span>Back</span>
            </button>
            <button
              phx-click="next_question"
              disabled={not @all_ready}
              class={[
                "flex-1 px-6 py-3 font-semibold rounded-lg transition-colors",
                if(@all_ready,
                  do: "bg-green-600 hover:bg-green-700 text-white",
                  else: "bg-gray-600 text-gray-400 cursor-not-allowed"
                )
              ]}
            >
              <%= if @session.current_question_index + 1 >= @total_questions do %>
                Continue to Summary →
              <% else %>
                Next Question →
              <% end %>
            </button>
          </div>
          <p class="text-center text-gray-500 text-sm mt-2">
            <%= if @all_ready do %>
              All participants ready
            <% else %>
              {@ready_count} of {@eligible_participant_count} participants ready
            <% end %>
          </p>
        <% else %>
          <%= if @participant_was_skipped do %>
            <!-- Skipped participant - automatically ready, greyed out -->
            <div class="text-center">
              <button
                disabled
                class="w-full px-6 py-3 bg-gray-600 text-gray-400 font-semibold rounded-lg cursor-not-allowed"
              >
                Ready to Continue
              </button>
              <p class="text-gray-500 text-sm mt-2">You were skipped for this question</p>
            </div>
          <% else %>
            <%= if @participant.is_ready do %>
              <div class="text-center text-gray-400">
                <span class="text-green-400">✓</span> You're ready. Waiting for facilitator...
              </div>
            <% else %>
              <button
                phx-click="mark_ready"
                class="w-full px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors"
              >
                I'm Ready to Continue
              </button>
            <% end %>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
