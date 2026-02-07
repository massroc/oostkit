defmodule WorkgroupPulseWeb.SessionLive.Components.SummaryComponent do
  @moduledoc """
  Renders the summary phase as a sheet in the carousel.
  Shows all scores with analysis and notes in a grid layout.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]

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
    <.sheet class="shadow-sheet p-6 w-[720px]">
      <!-- Header -->
      <div class="text-center mb-6 pb-4 border-b-2 border-ink-blue/10">
        <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-2">
          Workshop Summary
        </h1>
        <p class="text-ink-blue/70">
          Review your team's responses before creating action items.
        </p>
      </div>
      
    <!-- Participants -->
      <div class="bg-surface-wall/50 rounded-lg p-4 mb-6">
        <h2 class="text-sm font-semibold text-ink-blue/60 mb-3 font-brand uppercase tracking-wide">
          Participants
        </h2>
        <div class="flex flex-wrap gap-2">
          <%= for p <- @participants do %>
            <div class="bg-surface-sheet rounded-lg px-3 py-1.5 flex items-center gap-2 text-sm border border-ink-blue/5">
              <span class="font-workshop text-ink-blue">{p.name}</span>
              <%= cond do %>
                <% p.is_observer -> %>
                  <span class="text-xs bg-surface-wall text-ink-blue/60 px-1.5 py-0.5 rounded font-brand">
                    Observer
                  </span>
                <% p.is_facilitator -> %>
                  <span class="text-xs bg-accent-purple text-white px-1.5 py-0.5 rounded font-brand">
                    Facilitator
                  </span>
                <% true -> %>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Questions Grid -->
      <div class="space-y-4 mb-6">
        <%= for score <- @scores_summary do %>
          <% question_notes = Map.get(@notes_by_question, score.question_index, []) %>
          <% question_scores = Map.get(@individual_scores, score.question_index, []) %>
          <div class={["rounded-lg p-4 border", card_color_class(score.color)]}>
            <!-- Question header -->
            <div class="flex items-start justify-between mb-3">
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <span class="text-sm text-ink-blue/50 font-brand">
                    Q{score.question_index + 1}
                  </span>
                  <h3 class="font-workshop font-semibold text-ink-blue text-lg">{score.title}</h3>
                </div>
                <div class="text-xs text-ink-blue/40 mt-1 font-brand">
                  <%= if score.scale_type == "balance" do %>
                    -5 to +5, optimal at 0
                  <% else %>
                    0 to 10, higher is better
                  <% end %>
                </div>
              </div>

              <div class="text-right">
                <%= if score.combined_team_value do %>
                  <div class={["text-2xl font-bold font-workshop", text_color_class(score.color)]}>
                    {round(score.combined_team_value)}/10
                  </div>
                  <div class="flex items-center justify-end gap-1 text-xs text-ink-blue/40 font-brand">
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
                  <div class="text-ink-blue/40 text-sm font-brand">No scores</div>
                <% end %>
              </div>
            </div>
            
    <!-- Individual Scores -->
            <%= if length(question_scores) > 0 do %>
              <div class="flex flex-wrap gap-2 justify-center">
                <%= for s <- question_scores do %>
                  <div class={["rounded-lg p-2 text-center w-16 border", bg_color_class(s.color)]}>
                    <div class={["text-lg font-bold font-workshop", text_color_class(s.color)]}>
                      <%= if score.scale_type == "balance" and s.value > 0 do %>
                        +{s.value}
                      <% else %>
                        {s.value}
                      <% end %>
                    </div>
                    <div
                      class="text-xs text-ink-blue/60 truncate font-workshop"
                      title={s.participant_name}
                    >
                      {s.participant_name}
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
            
    <!-- Notes -->
            <%= if length(question_notes) > 0 do %>
              <div class="mt-3 pt-3 border-t border-ink-blue/10">
                <div class="text-xs text-ink-blue/40 mb-2 font-brand uppercase tracking-wide">
                  Notes
                </div>
                <ul class="space-y-1.5">
                  <%= for note <- question_notes do %>
                    <li class="text-sm text-ink-blue/70 bg-surface-wall/50 rounded px-2 py-1.5">
                      <span class="font-workshop">{note.content}</span>
                      <span class="text-xs text-ink-blue/40 ml-1 font-brand">
                        — {note.author_name}
                      </span>
                    </li>
                  <% end %>
                </ul>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
      
    <!-- Navigation Footer -->
      <div class="pt-4 border-t border-ink-blue/10">
        <%= if @participant.is_facilitator do %>
          <div class="flex gap-3">
            <button
              phx-click="go_back"
              class="btn-workshop btn-workshop-secondary"
            >
              ← Back
            </button>
            <button
              phx-click="continue_to_wrapup"
              class="flex-1 btn-workshop btn-workshop-primary"
            >
              Continue to Wrap-Up →
            </button>
          </div>
          <p class="text-center text-ink-blue/50 text-sm mt-2 font-brand">
            Proceed to create action items and finish the workshop.
          </p>
        <% else %>
          <div class="text-center text-ink-blue/60 font-brand">
            Reviewing summary. Waiting for facilitator to continue...
          </div>
        <% end %>
      </div>
    </.sheet>
    """
  end
end
