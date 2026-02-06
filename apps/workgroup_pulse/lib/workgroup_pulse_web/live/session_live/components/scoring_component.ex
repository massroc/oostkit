defmodule WorkgroupPulseWeb.SessionLive.Components.ScoringComponent do
  @moduledoc """
  Renders the scoring phase of a workshop session.
  Features the Virtual Wall design with paper-textured sheets,
  grid-based scoring view, and side-sheet for notes.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  alias WorkgroupPulseWeb.SessionLive.ScoreResultsComponent

  import WorkgroupPulseWeb.SessionLive.ScoreHelpers

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :participants, :list, required: true
  attr :current_question, :map, required: true
  attr :total_questions, :integer, required: true
  attr :all_scores, :list, required: true
  attr :selected_value, :any, required: true
  attr :my_score, :any, required: true
  attr :has_submitted, :boolean, required: true
  attr :is_my_turn, :boolean, required: true
  attr :current_turn_participant_id, :any, required: true
  attr :current_turn_has_score, :boolean, required: true
  attr :my_turn_locked, :boolean, required: true
  attr :scores_revealed, :boolean, required: true
  attr :score_count, :integer, required: true
  attr :active_participant_count, :integer, required: true
  attr :show_mid_transition, :boolean, required: true
  attr :show_facilitator_tips, :boolean, required: true
  attr :question_notes, :list, required: true
  attr :active_sheet, :atom, required: true
  attr :note_input, :string, required: true
  attr :ready_count, :integer, required: true
  attr :eligible_participant_count, :integer, required: true
  attr :all_ready, :boolean, required: true
  attr :participant_was_skipped, :boolean, required: true

  def render(assigns) do
    ~H"""
    <%= if @show_mid_transition do %>
      {render_mid_transition(assigns)}
    <% else %>
      <div class="flex h-full relative">
        <!-- Main Content Area -->
        <div class="flex-1 flex items-start justify-center p-6 overflow-auto relative">
          <!-- Main Sheet -->
          <div
            class={[
              "paper-texture rounded-sheet p-5 min-w-[520px] max-w-[700px] w-full relative flex flex-col cursor-pointer transition-all duration-300",
              if(@active_sheet == :main, do: "shadow-sheet-lifted z-[10]", else: "shadow-sheet z-[1]")
            ]}
            style="transform: rotate(-0.2deg)"
            phx-click="focus_sheet"
            phx-value-sheet="main"
          >
            <div class="relative z-[1] flex-1 flex flex-col">
              <!-- Sheet Header: Question info + Progress -->
              <div class="mb-4 pb-3 border-b-2 border-ink-blue/10">
                <div class="flex justify-between items-center text-sm mb-2">
                  <span class="text-ui-text-muted">
                    Question {@session.current_question_index + 1} of {@total_questions}
                  </span>
                  <span class="text-ui-text-muted">
                    {@score_count}/{@active_participant_count} scored
                  </span>
                </div>

                <h2 class="font-workshop text-2xl font-bold text-ink-blue">
                  {@current_question.title}
                </h2>

                <p class="text-ink-blue/70 text-sm mt-1 whitespace-pre-line">
                  {format_description(@current_question.explanation)}
                </p>

                <%= if length(@current_question.discussion_prompts) > 0 do %>
                  <%= if @show_facilitator_tips do %>
                    <div class="mt-3 pt-3 border-t border-ink-blue/10">
                      <div class="flex items-center justify-between mb-2">
                        <h3 class="text-xs font-semibold text-accent-purple uppercase tracking-wide">
                          Facilitator Tips
                        </h3>
                        <button
                          type="button"
                          phx-click="toggle_facilitator_tips"
                          class="text-xs text-ui-text-muted hover:text-ui-text transition-colors"
                        >
                          Hide
                        </button>
                      </div>
                      <ul class="space-y-1">
                        <%= for prompt <- @current_question.discussion_prompts do %>
                          <li class="flex gap-2 text-ink-blue/60 text-sm">
                            <span class="text-accent-purple">•</span>
                            <span>{prompt}</span>
                          </li>
                        <% end %>
                      </ul>
                    </div>
                  <% else %>
                    <button
                      type="button"
                      phx-click="toggle_facilitator_tips"
                      class="mt-2 text-sm text-accent-purple hover:text-highlight transition-colors flex items-center gap-1"
                    >
                      <span>More tips</span>
                      <span class="text-xs">+</span>
                    </button>
                  <% end %>
                <% end %>
              </div>
              
    <!-- Grid-based Score Display -->
              <%= if length(@all_scores) > 0 and not @scores_revealed do %>
                <div class="flex-1 overflow-y-auto overflow-x-hidden mb-4">
                  {render_scoring_grid(assigns)}
                </div>
              <% end %>
              
    <!-- Score Results (after reveal) -->
              <%= if @scores_revealed and not (@is_my_turn and not @my_turn_locked) do %>
                <.live_component
                  module={ScoreResultsComponent}
                  id="score-results"
                  all_scores={@all_scores}
                  current_question={@current_question}
                  total_questions={@total_questions}
                  participant={@participant}
                  session={@session}
                  ready_count={@ready_count}
                  eligible_participant_count={@eligible_participant_count}
                  all_ready={@all_ready}
                  participant_was_skipped={@participant_was_skipped}
                />
              <% else %>
                <!-- Score Input Area -->
                {render_score_input(assigns)}
              <% end %>
              
    <!-- Facilitator Navigation (during scoring entry) -->
              <%= if @participant.is_facilitator and not @scores_revealed do %>
                <div class="mt-4 pt-4 border-t border-ink-blue/10">
                  <div class="flex gap-3">
                    <%= if @session.current_question_index > 0 do %>
                      <button
                        phx-click="go_back"
                        class="btn-workshop btn-workshop-secondary"
                      >
                        ← Back
                      </button>
                    <% end %>
                    <button
                      disabled
                      class="flex-1 btn-workshop btn-workshop-secondary opacity-50 cursor-not-allowed"
                    >
                      <%= if @session.current_question_index + 1 >= @total_questions do %>
                        Continue to Summary →
                      <% else %>
                        Next Question →
                      <% end %>
                    </button>
                  </div>
                  <p class="text-center text-ui-text-muted text-xs mt-2">
                    Waiting for all scores to be submitted...
                  </p>
                </div>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Side Sheet (Notes) -->
        <div
          class={[
            "absolute right-5 top-6 transition-all duration-300",
            if(@active_sheet == :notes, do: "z-[20]", else: "z-[5]")
          ]}
          style="margin-top: 40px;"
          phx-click="focus_sheet"
          phx-value-sheet="notes"
        >
          <div class={[
            "paper-texture-secondary rounded-sheet p-4 overflow-hidden cursor-pointer transition-all duration-300",
            if(@active_sheet == :notes,
              do: "w-[320px] shadow-sheet-lifted",
              else: "w-[280px] shadow-sheet hover:shadow-sheet-lifted"
            )
          ]}>
            <div class="relative z-[1]">
              <!-- Header -->
              <div class="flex items-center justify-between mb-3">
                <div class="font-workshop text-xl font-bold text-ink-blue underline underline-offset-[3px] decoration-[1.5px] decoration-ink-blue/20 opacity-85">
                  Notes
                  <%= if length(@question_notes) > 0 do %>
                    <span class="text-sm font-normal text-ink-blue/50 ml-1">
                      ({length(@question_notes)})
                    </span>
                  <% end %>
                </div>
              </div>

              <%= if @active_sheet == :notes do %>
                <!-- Active: Show add form and full notes list -->
                <form phx-submit="add_note" class="mb-3">
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

                <div class="space-y-2 max-h-[300px] overflow-y-auto">
                  <%= if length(@question_notes) > 0 do %>
                    <%= for note <- @question_notes do %>
                      <div class="bg-surface-sheet/50 rounded p-2 text-sm group">
                        <div class="flex justify-between items-start gap-1">
                          <p class="font-workshop text-ink-blue flex-1">{note.content}</p>
                          <button
                            type="button"
                            phx-click="delete_note"
                            phx-value-id={note.id}
                            class="text-ink-blue/30 hover:text-traffic-red transition-colors opacity-0 group-hover:opacity-100"
                          >
                            ✕
                          </button>
                        </div>
                        <p class="text-xs text-ink-blue/40 mt-1 font-brand">— {note.author_name}</p>
                      </div>
                    <% end %>
                  <% else %>
                    <p class="text-center text-ink-blue/50 text-sm italic font-workshop">
                      No notes yet. Type above to add one.
                    </p>
                  <% end %>
                </div>
              <% else %>
                <!-- Inactive: Show preview -->
                <div class="font-workshop text-ink-blue leading-relaxed opacity-70">
                  <%= if length(@question_notes) > 0 do %>
                    <%= for note <- Enum.take(@question_notes, 2) do %>
                      <p class="mb-2 relative pl-4 text-sm">
                        <span class="absolute left-0 text-ink-blue/60">•</span>
                        {String.slice(note.content, 0, 30)}{if String.length(note.content) > 30,
                          do: "..."}
                      </p>
                    <% end %>
                    <%= if length(@question_notes) > 2 do %>
                      <p class="text-xs opacity-60 text-center">
                        +{length(@question_notes) - 2} more
                      </p>
                    <% end %>
                  <% else %>
                    <p class="text-center text-ink-blue/50 italic text-sm">
                      Click to add notes...
                    </p>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp render_mid_transition(assigns) do
    ~H"""
    <div class="flex items-center justify-center h-full p-6">
      <div
        class="paper-texture rounded-sheet shadow-sheet p-8 max-w-2xl w-full"
        style="transform: rotate(-0.2deg)"
      >
        <div class="relative z-[1] text-center">
          <div class="text-6xl mb-4">🔄</div>

          <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-6">
            New Scoring Scale Ahead
          </h1>

          <div class="text-ink-blue/80 space-y-4 text-lg text-left">
            <p class="text-center">Great progress! You've completed the first four questions.</p>

            <div class="bg-surface-wall rounded-lg p-6 my-6">
              <p class="text-ink-blue font-semibold mb-3">
                The next four questions use a different scale:
              </p>

              <div class="flex justify-between items-center mb-4">
                <span class="text-ink-blue/60">0</span>
                <span class="text-traffic-green font-semibold text-xl">→</span>
                <span class="text-traffic-green font-semibold">10</span>
              </div>

              <ul class="space-y-2 text-ink-blue/70">
                <li>
                  • For these,
                  <span class="text-traffic-green font-semibold">more is always better</span>
                </li>
                <li>• <span class="text-traffic-green font-semibold">10 is optimal</span></li>
              </ul>
            </div>

            <p class="text-ink-blue/60 text-center">
              These measure aspects of work where you can never have too much.
            </p>
          </div>

          <button
            phx-click="continue_past_transition"
            class="mt-8 btn-workshop btn-workshop-primary text-lg px-8 py-3"
          >
            Continue to Question 5 →
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp render_scoring_grid(assigns) do
    # Get active (non-observer) participants for the grid
    active_participants =
      Enum.filter(assigns.participants, fn p -> not p.is_observer end)

    # Build scores map for quick lookup
    scores_by_participant =
      assigns.all_scores
      |> Enum.map(fn s -> {s.participant_id, s} end)
      |> Map.new()

    assigns =
      assigns
      |> assign(:active_participants, active_participants)
      |> assign(:scores_by_participant, scores_by_participant)

    ~H"""
    <table class="scoring-grid">
      <thead>
        <tr>
          <th class="criterion-col"></th>
          <%= for p <- @active_participants do %>
            <th class={[
              "participant-col",
              p.id == @current_turn_participant_id && "active-col-header"
            ]}>
              {p.name}
            </th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <!-- Current question row (active) -->
        <tr class="active-row">
          <td class="criterion">
            <%= if @current_question.criterion_name && @current_question.criterion_name != @current_question.title do %>
              <span class="parent">{@current_question.criterion_name}</span>
            <% end %>
            <span class="name">{@current_question.title}</span>
          </td>
          <%= for p <- @active_participants do %>
            <% score = Map.get(@scores_by_participant, p.id) %>
            <td class={[
              "score-cell",
              score && score.state == :empty && "empty",
              p.id == @current_turn_participant_id && "active-col"
            ]}>
              <%= if score do %>
                <%= case score.state do %>
                  <% :scored -> %>
                    <%= if @current_question.scale_type == "balance" and score.value > 0 do %>
                      +{score.value}
                    <% else %>
                      {score.value}
                    <% end %>
                  <% :current -> %>
                    ...
                  <% :skipped -> %>
                    ?
                  <% _ -> %>
                    —
                <% end %>
              <% else %>
                —
              <% end %>
            </td>
          <% end %>
        </tr>
      </tbody>
    </table>
    """
  end

  defp render_score_input(assigns) do
    # Find current turn participant name for display
    current_turn_name =
      if assigns.current_turn_participant_id do
        Enum.find_value(assigns.participants, "Unknown", fn p ->
          if p.id == assigns.current_turn_participant_id, do: p.name
        end)
      else
        nil
      end

    assigns = assign(assigns, :current_turn_name, current_turn_name)

    ~H"""
    <div class="bg-surface-wall/50 rounded-lg p-4">
      <%= if @participant.is_observer do %>
        <div class="text-center">
          <div class="text-accent-purple text-lg font-semibold mb-2 font-brand">Observer Mode</div>
          <p class="text-ink-blue/70">You are observing this session.</p>
          <%= if @current_turn_name do %>
            <p class="text-ink-blue/50 mt-2">
              <span class="text-ink-blue">{@current_turn_name}</span> is scoring
            </p>
          <% end %>
        </div>
      <% else %>
        <%= if @is_my_turn and not @my_turn_locked do %>
          <!-- It's this participant's turn -->
          <div class="text-center mb-4">
            <div class="text-traffic-green text-lg font-semibold font-brand">
              <%= if @has_submitted do %>
                Discuss your score
              <% else %>
                Your turn to score
              <% end %>
            </div>
          </div>

          <%= if @current_question.scale_type == "balance" do %>
            {render_balance_scale(assigns)}
          <% else %>
            {render_maximal_scale(assigns)}
          <% end %>

          <%= if @has_submitted do %>
            <p class="text-center text-ink-blue/60 text-sm mt-3">
              Discuss this score, then click "Done" when ready
            </p>
          <% end %>
        <% else %>
          <!-- Not this participant's turn -->
          <div class="text-center">
            <%= if @current_turn_name do %>
              <p class="text-ink-blue/70">
                <%= if @current_turn_has_score do %>
                  Discuss <span class="text-ink-blue font-semibold">{@current_turn_name}</span>'s score
                <% else %>
                  Waiting for <span class="text-ink-blue font-semibold">{@current_turn_name}</span>
                  to score
                <% end %>
              </p>
              <!-- Skip button - facilitator only -->
              <%= if @participant.is_facilitator and not @current_turn_has_score do %>
                <div class="mt-3">
                  <button
                    phx-click="skip_turn"
                    class="text-sm text-ui-text-muted hover:text-ink-blue transition-colors"
                  >
                    Skip {String.split(@current_turn_name) |> List.first()}'s turn
                  </button>
                </div>
              <% end %>
            <% else %>
              <p class="text-ink-blue/60">Waiting for next turn...</p>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp render_balance_scale(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex justify-between text-sm text-ink-blue/60">
        <span>Too little</span>
        <span>Just right</span>
        <span>Too much</span>
      </div>

      <div class="flex gap-1">
        <%= for v <- -5..5 do %>
          <button
            type="button"
            phx-click="select_score"
            phx-value-score={v}
            class={[
              "flex-1 min-w-0 py-2.5 rounded-lg font-semibold text-sm transition-all cursor-pointer font-workshop",
              cond do
                @selected_value == v ->
                  "bg-traffic-green text-white shadow-md"

                v == 0 ->
                  "bg-green-100 text-traffic-green border-2 border-traffic-green hover:bg-green-200"

                true ->
                  "bg-surface-sheet text-ink-blue hover:bg-surface-sheet-secondary border border-ink-blue/10"
              end
            ]}
          >
            <%= if v > 0 do %>
              +{v}
            <% else %>
              {v}
            <% end %>
          </button>
        <% end %>
      </div>

      <div class="flex justify-between text-xs text-ink-blue/50">
        <span>-5</span>
        <span class="text-traffic-green font-semibold">0 = optimal</span>
        <span>+5</span>
      </div>
    </div>
    """
  end

  defp render_maximal_scale(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex justify-between text-sm text-ink-blue/60">
        <span>Low</span>
        <span>High</span>
      </div>

      <div class="flex gap-1">
        <%= for v <- 0..10 do %>
          <button
            type="button"
            phx-click="select_score"
            phx-value-score={v}
            class={[
              "flex-1 min-w-0 py-2.5 rounded-lg font-semibold text-sm transition-all cursor-pointer font-workshop",
              if(@selected_value == v,
                do: "bg-accent-purple text-white shadow-md",
                else:
                  "bg-surface-sheet text-ink-blue hover:bg-surface-sheet-secondary border border-ink-blue/10"
              )
            ]}
          >
            {v}
          </button>
        <% end %>
      </div>

      <div class="flex justify-between text-xs text-ink-blue/50">
        <span>0</span>
        <span>10</span>
      </div>
    </div>
    """
  end
end
