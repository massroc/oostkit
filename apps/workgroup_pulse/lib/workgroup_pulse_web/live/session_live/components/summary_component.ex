defmodule WorkgroupPulseWeb.SessionLive.Components.SummaryComponent do
  @moduledoc """
  Renders the summary phase of a workshop session.
  Shows all scores with analysis and notes.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.SessionLive.ScoreHelpers,
    only: [text_color_class: 1, bg_color_class: 1, card_color_class: 1]

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :participants, :list, required: true
  attr :scores_summary, :list, required: true
  attr :individual_scores, :map, required: true
  attr :notes_by_question, :map, required: true

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center min-h-screen px-4 py-8">
      <div class="max-w-4xl w-full">
        <div class="text-center mb-8">
          <h1 class="text-3xl font-bold text-text-dark mb-2">Workshop Summary</h1>

          <p class="text-text-body">Review your team's responses before creating action items.</p>
        </div>
        <!-- Participants -->
        <div class="bg-surface-sheet rounded-lg p-4 mb-6">
          <h2 class="text-sm font-semibold text-text-body mb-3">Participants</h2>

          <div class="flex flex-wrap gap-2">
            <%= for p <- @participants do %>
              <div class="bg-gray-100 rounded-lg px-3 py-1.5 flex items-center gap-2 text-sm">
                <span class="text-text-dark">{p.name}</span>
                <%= cond do %>
                  <% p.is_observer -> %>
                    <span class="text-xs bg-gray-600 text-text-body px-1.5 py-0.5 rounded">
                      Observer
                    </span>
                  <% p.is_facilitator -> %>
                    <span class="text-xs bg-purple-600 text-text-dark px-1.5 py-0.5 rounded">
                      Facilitator
                    </span>
                  <% true -> %>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
        <!-- All Questions with Individual Scores and Notes -->
        <div class="space-y-4 mb-6">
          <%= for score <- @scores_summary do %>
            <% question_notes = Map.get(@notes_by_question, score.question_index, []) %> <% question_scores =
              Map.get(@individual_scores, score.question_index, []) %>
            <div class={["rounded-lg p-4 border", card_color_class(score.color)]}>
              <!-- Question header -->
              <div class="flex items-start justify-between mb-3">
                <div class="flex-1">
                  <div class="flex items-center gap-2">
                    <span class="text-sm text-text-body">Q{score.question_index + 1}</span>
                    <h3 class="font-semibold text-text-dark">{score.title}</h3>
                  </div>

                  <div class="text-xs text-gray-500 mt-1">
                    <%= if score.scale_type == "balance" do %>
                      -5 to +5, optimal at 0
                    <% else %>
                      0 to 10, higher is better
                    <% end %>
                  </div>
                </div>

                <div class="text-right">
                  <%= if score.combined_team_value do %>
                    <div class={["text-2xl font-bold", text_color_class(score.color)]}>
                      {round(score.combined_team_value)}/10
                    </div>

                    <div class="flex items-center justify-end gap-1 text-xs text-gray-500">
                      <span>team</span>
                      <span
                        class="cursor-help"
                        title="Combined Team Value: A team rating out of 10 for this criterion. Each person's score is graded (green=2, amber=1, red=0), then averaged and scaled. 10 = everyone scored well, 0 = everyone scored poorly."
                      >
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                          />
                        </svg>
                      </span>
                    </div>
                  <% else %>
                    <div class="text-gray-500 text-sm">No scores</div>
                  <% end %>
                </div>
              </div>
              <!-- Individual Scores with names -->
              <%= if length(question_scores) > 0 do %>
                <div class="flex flex-wrap gap-2 justify-center">
                  <%= for s <- question_scores do %>
                    <div class={["rounded p-2 text-center w-16", bg_color_class(s.color)]}>
                      <div class={["text-lg font-bold", text_color_class(s.color)]}>
                        <%= if score.scale_type == "balance" and s.value > 0 do %>
                          +{s.value}
                        <% else %>
                          {s.value}
                        <% end %>
                      </div>

                      <div class="text-xs text-text-body truncate" title={s.participant_name}>
                        {s.participant_name}
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
              <!-- Notes for this question (inline) -->
              <%= if length(question_notes) > 0 do %>
                <div class="mt-3 pt-3 border-t border-gray-700/50">
                  <div class="text-xs text-gray-500 mb-2">Notes</div>

                  <ul class="space-y-1.5">
                    <%= for note <- question_notes do %>
                      <li class="text-sm text-text-body bg-gray-100/50 rounded px-2 py-1.5">
                        {note.content}
                        <span class="text-xs text-gray-500 ml-1">— {note.author_name}</span>
                      </li>
                    <% end %>
                  </ul>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
        <!-- Navigation Footer -->
        <div class="bg-surface-sheet rounded-lg p-6">
          <%= if @participant.is_facilitator do %>
            <div class="flex gap-3">
              <button
                phx-click="go_back"
                class="px-6 py-3 bg-gray-100 hover:bg-gray-600 text-text-body hover:text-text-dark font-medium rounded-lg transition-colors flex items-center gap-2"
              >
                <span>←</span> <span>Back</span>
              </button>
              <button
                phx-click="continue_to_wrapup"
                class="flex-1 px-6 py-3 bg-df-green hover:bg-secondary-green-light text-white font-semibold rounded-lg transition-colors"
              >
                Continue to Wrap-Up →
              </button>
            </div>

            <p class="text-center text-gray-500 text-sm mt-2">
              Proceed to create action items and finish the workshop.
            </p>
          <% else %>
            <div class="text-center text-text-body">
              Reviewing summary. Waiting for facilitator to continue...
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
