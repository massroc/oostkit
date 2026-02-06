defmodule WorkgroupPulseWeb.SessionLive.Components.ScoringComponent do
  @moduledoc """
  Renders the scoring phase of a workshop session.
  Features the Virtual Wall design with full 8-question grid,
  floating score input overlay, and side-sheet for notes.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

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
  attr :all_questions, :list, required: true
  attr :all_questions_scores, :map, required: true
  attr :show_score_overlay, :boolean, required: true

  def render(assigns) do
    ~H"""
    <%= if @show_mid_transition do %>
      {render_mid_transition(assigns)}
    <% else %>
      <div class="flex items-start justify-center h-full w-full relative pt-8">
        <!-- Main Sheet - centered -->
        <div
          class={[
            "paper-texture rounded-sheet p-5 w-[720px] cursor-pointer transition-all duration-300",
            if(@active_sheet == :main,
              do: "shadow-sheet-lifted z-[10]",
              else: "shadow-sheet z-[1]"
            )
          ]}
          style="transform: rotate(-0.2deg)"
          phx-click="focus_sheet"
          phx-value-sheet="main"
        >
          <div class="relative z-[1]">
            <!-- Full Scoring Grid -->
            <%= if length(@all_questions) > 0 do %>
              <div class="overflow-y-auto overflow-x-hidden">
                {render_full_scoring_grid(assigns)}
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Left Panel: Question Info - absolutely positioned -->
        <div class="absolute left-4 top-1/2 -translate-y-1/2 z-[5] w-[220px]">
          <div
            class="paper-texture-secondary rounded-sheet p-4 shadow-sheet"
            style="transform: rotate(0.3deg)"
          >
            <div class="relative z-[1]">
              <h2 class="font-workshop text-xl font-bold text-ink-blue leading-tight">
                {@current_question.title}
              </h2>

              <p class="text-ink-blue/70 text-sm mt-2 whitespace-pre-line">
                {format_description(@current_question.explanation)}
              </p>

              <%= if length(@current_question.discussion_prompts) > 0 do %>
                <%= if @show_facilitator_tips do %>
                  <div class="mt-3 pt-3 border-t border-ink-blue/10">
                    <div class="flex items-center justify-between mb-2">
                      <h3 class="text-xs font-semibold text-accent-purple uppercase tracking-wide">
                        Tips
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
                    class="mt-3 text-sm text-accent-purple hover:text-highlight transition-colors flex items-center gap-1"
                  >
                    <span>More tips</span>
                    <span class="text-xs">+</span>
                  </button>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
        
    <!-- Side Sheet (Notes) - absolutely positioned -->
        <div
          class={[
            "absolute right-4 top-16 transition-all duration-300",
            if(@active_sheet == :notes, do: "z-[20]", else: "z-[5]")
          ]}
          phx-click="focus_sheet"
          phx-value-sheet="notes"
        >
          <div class={[
            "paper-texture-secondary rounded-sheet p-4 overflow-hidden cursor-pointer transition-all duration-300 min-h-[360px]",
            if(@active_sheet == :notes,
              do: "w-[320px] shadow-sheet-lifted",
              else: "w-[280px] shadow-sheet hover:shadow-sheet-lifted"
            )
          ]}>
            <div class="relative z-[1]">
              <!-- Header -->
              <div class="text-center mb-3">
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
      
    <!-- Score Input Overlay (only for person scoring, when overlay is open) -->
      <%= if @is_my_turn and not @my_turn_locked and @show_score_overlay do %>
        {render_score_overlay(assigns)}
      <% end %>
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

  # Fixed number of participant column slots to maintain consistent grid width
  @grid_participant_slots 7

  defp render_full_scoring_grid(assigns) do
    # Get active (non-observer) participants for the grid
    active_participants =
      Enum.filter(assigns.participants, fn p -> not p.is_observer end)

    # Separate questions by scale type
    balance_questions = Enum.filter(assigns.all_questions, &(&1.scale_type == "balance"))
    maximal_questions = Enum.filter(assigns.all_questions, &(&1.scale_type == "maximal"))

    # Calculate empty padding slots to maintain fixed grid width
    empty_slots = max(@grid_participant_slots - length(active_participants), 0)

    assigns =
      assigns
      |> assign(:active_participants, active_participants)
      |> assign(:balance_questions, balance_questions)
      |> assign(:maximal_questions, maximal_questions)
      |> assign(:empty_slots, empty_slots)

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
          <%= for _ <- 1..@empty_slots//1 do %>
            <th class="participant-col"></th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <!-- Scale label: Balance -->
        <tr>
          <td class="scale-label" colspan={length(@active_participants) + @empty_slots + 1}>
            Balance Scale (-5 to +5)
          </td>
        </tr>
        <!-- Balance questions (index 0-3) -->
        <%= for q <- @balance_questions do %>
          {render_question_row(assigns, q)}
        <% end %>
        <!-- Scale label: Maximal -->
        <tr>
          <td class="scale-label" colspan={length(@active_participants) + @empty_slots + 1}>
            Maximal Scale (0 to 10)
          </td>
        </tr>
        <!-- Maximal questions (index 4-7) -->
        <%= for q <- @maximal_questions do %>
          {render_question_row(assigns, q)}
        <% end %>
      </tbody>
    </table>
    """
  end

  defp render_question_row(assigns, question) do
    is_current = question.index == assigns.current_question.index
    is_past = question.index < assigns.session.current_question_index
    is_future = question.index > assigns.session.current_question_index

    # Get scores for this question
    question_scores = Map.get(assigns.all_questions_scores, question.index, [])

    # Build a map of participant_id -> score data for this question
    scores_by_participant = Map.new(question_scores, &{&1.participant_id, &1})

    assigns =
      assigns
      |> assign(:question, question)
      |> assign(:is_current, is_current)
      |> assign(:is_past, is_past)
      |> assign(:is_future, is_future)
      |> assign(:question_scores_by_participant, scores_by_participant)

    ~H"""
    <tr class={@is_current && "active-row"}>
      <td class="criterion">
        <%= if @question.criterion_name && @question.criterion_name != @question.title do %>
          <span class="parent">{@question.criterion_name}</span>
        <% end %>
        <span class="name">{format_criterion_title(@question.title)}</span>
      </td>
      <%= for p <- @active_participants do %>
        <% score_data = Map.get(@question_scores_by_participant, p.id) %>
        <% can_interact =
          @is_current and p.id == @participant.id and @is_my_turn and not @my_turn_locked %>
        <td
          class={[
            "score-cell",
            @is_current && p.id == @current_turn_participant_id && "active-col",
            not @is_current && p.id == @current_turn_participant_id && "active-col",
            can_interact && "cursor-pointer hover:bg-accent-purple-light",
            can_interact && not @has_submitted && "outline outline-2 outline-accent-purple rounded"
          ]}
          phx-click={can_interact && "edit_my_score"}
        >
          <%= if can_interact and not @has_submitted do %>
            <span class="text-[11px] leading-tight text-accent-purple font-workshop block">
              Click to<br />score
            </span>
          <% else %>
            {render_score_cell_value(assigns, score_data, p.id)}
          <% end %>
        </td>
      <% end %>
      <%= for _ <- 1..@empty_slots//1 do %>
        <td class="score-cell"></td>
      <% end %>
    </tr>
    """
  end

  # Future questions - show dash
  defp render_score_cell_value(%{is_future: true}, _score_data, _participant_id), do: "—"

  # Past questions - show actual score or "?" for skipped
  defp render_score_cell_value(%{is_past: true} = assigns, %{has_score: true, value: value}, _) do
    format_score_value(assigns.question.scale_type, value)
  end

  defp render_score_cell_value(%{is_past: true}, _score_data, _participant_id), do: "?"

  # Current question with score - show it
  defp render_score_cell_value(%{is_current: true} = assigns, %{has_score: true, value: value}, _) do
    format_score_value(assigns.question.scale_type, value)
  end

  # Current question, current turn participant hasn't scored yet
  defp render_score_cell_value(
         %{is_current: true, current_turn_participant_id: turn_id},
         _score_data,
         participant_id
       )
       when participant_id == turn_id,
       do: "..."

  # Current question, hasn't had their turn yet
  defp render_score_cell_value(%{is_current: true}, _score_data, _participant_id), do: "—"

  # Fallback
  defp render_score_cell_value(_assigns, _score_data, _participant_id), do: "—"

  defp format_score_value("balance", value) when value > 0, do: "+#{value}"
  defp format_score_value(_, value), do: "#{value}"

  defp format_criterion_title("Mutual Support and Respect") do
    Phoenix.HTML.raw("Mutual Support<br/><span style=\"padding-left:8px\">and Respect</span>")
  end

  defp format_criterion_title(title), do: title

  defp render_score_overlay(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center score-overlay-enter">
      <!-- Backdrop -->
      <div class="absolute inset-0 bg-ink-blue/30 backdrop-blur-sm" phx-click="close_score_overlay"></div>
      <!-- Modal -->
      <div class="relative paper-texture rounded-sheet shadow-sheet-lifted p-6 max-w-md w-full mx-4">
        <div class="relative z-[1]">
          <h3 class="font-workshop text-xl font-bold text-ink-blue text-center mb-2">
            {@current_question.title}
          </h3>

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
        </div>
      </div>
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
