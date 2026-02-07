defmodule WorkgroupPulseWeb.SessionLive.Components.ScoringComponent do
  @moduledoc """
  Renders the scoring phase as a sheet in the carousel.
  Features the full 8-question grid, floating score input overlay,
  and criterion info popup.
  The notes/actions slide is managed by the scoring carousel in show.ex.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]
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
  attr :show_criterion_popup, :any, required: true
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
      <!-- Main Sheet with scoring grid -->
      <.sheet
        class="p-5 w-[720px] h-full shadow-sheet-lifted transition-all duration-300"
        phx-click="focus_sheet"
        phx-value-sheet="main"
      >
        <!-- Full Scoring Grid -->
        <%= if length(@all_questions) > 0 do %>
          {render_full_scoring_grid(assigns)}
        <% end %>
      </.sheet>
      
    <!-- Score Input Overlay (only for person scoring, when overlay is open) -->
      <%= if @is_my_turn and not @my_turn_locked and @show_score_overlay do %>
        {render_score_overlay(assigns)}
      <% end %>
      
    <!-- Criterion Info Popup -->
      <%= if @show_criterion_popup != nil do %>
        {render_criterion_popup(assigns)}
      <% end %>
    <% end %>
    """
  end

  defp render_mid_transition(assigns) do
    ~H"""
    <.sheet class="shadow-sheet p-8 w-[720px] h-full">
      <div class="text-center">
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
    </.sheet>
    """
  end

  # Fixed number of participant column slots to maintain consistent grid width
  @grid_participant_slots 7

  # Questions that are first of a paired criterion — emit a header row before them
  @first_of_pair MapSet.new(["2a", "5a"])

  defp sub_label(question) do
    cn = question.criterion_number

    cond do
      String.ends_with?(cn, "a") -> "a"
      String.ends_with?(cn, "b") -> "b"
      true -> nil
    end
  end

  defp render_full_scoring_grid(assigns) do
    # Get active (non-observer) participants for the grid
    active_participants =
      Enum.filter(assigns.participants, fn p -> not p.is_observer end)

    # Separate questions by scale type
    balance_questions = Enum.filter(assigns.all_questions, &(&1.scale_type == "balance"))
    maximal_questions = Enum.filter(assigns.all_questions, &(&1.scale_type == "maximal"))

    # Calculate empty padding slots to maintain fixed grid width
    empty_slots = max(@grid_participant_slots - length(active_participants), 0)
    total_cols = 1 + length(active_participants) + empty_slots

    assigns =
      assigns
      |> assign(:active_participants, active_participants)
      |> assign(:balance_questions, balance_questions)
      |> assign(:maximal_questions, maximal_questions)
      |> assign(:empty_slots, empty_slots)
      |> assign(:total_cols, total_cols)

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
          <td class="scale-label" colspan={@total_cols}>
            Balance Scale (-5 to +5)
          </td>
        </tr>
        <!-- Balance questions (index 0-3) -->
        <%= for q <- @balance_questions do %>
          {render_question_row(assigns, q)}
        <% end %>
        <!-- Scale label: Maximal -->
        <tr>
          <td class="scale-label" colspan={@total_cols}>
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

    is_first_of_pair = MapSet.member?(@first_of_pair, question.criterion_number)
    label = sub_label(question)

    assigns =
      assigns
      |> assign(:question, question)
      |> assign(:is_current, is_current)
      |> assign(:is_past, is_past)
      |> assign(:is_future, is_future)
      |> assign(:question_scores_by_participant, scores_by_participant)
      |> assign(:is_first_of_pair, is_first_of_pair)
      |> assign(:sub_label, label)

    ~H"""
    <%= if @is_first_of_pair do %>
      <tr>
        <td class="criterion-group-header" colspan={@total_cols}>
          {@question.criterion_name}
        </td>
      </tr>
    <% end %>
    <tr class={@is_current && "active-row"}>
      <td
        class={[
          "criterion cursor-pointer hover:bg-accent-purple-light/50 transition-colors",
          @sub_label && "criterion-indented"
        ]}
        phx-click="show_criterion_info"
        phx-value-index={@question.index}
      >
        <span class="name">
          <%= if @sub_label do %>
            <span style="text-transform: lowercase">{@sub_label}.</span> {format_criterion_title(
              @question.title
            )}
          <% else %>
            {format_criterion_title(@question.title)}
          <% end %>
        </span>
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

  # ═══════════════════════════════════════════════════════════════════════════
  # Criterion Info Popup
  # ═══════════════════════════════════════════════════════════════════════════

  defp render_criterion_popup(assigns) do
    popup_question =
      Enum.find(assigns.all_questions, fn q -> q.index == assigns.show_criterion_popup end)

    assigns = assign(assigns, :popup_question, popup_question)

    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center score-overlay-enter" data-no-navigate>
      <!-- Backdrop -->
      <div
        class="absolute inset-0 bg-ink-blue/30 backdrop-blur-sm"
        phx-click="close_criterion_info"
      >
      </div>
      <!-- Popup -->
      <.sheet class="shadow-sheet-lifted p-6 max-w-md w-full mx-4 relative max-h-[80vh] overflow-y-auto">
        <h2 class="font-workshop text-2xl font-bold text-ink-blue leading-tight mb-1">
          {@popup_question.title}
        </h2>

        <%= if @popup_question.criterion_name && @popup_question.criterion_name != @popup_question.title do %>
          <div class="text-xs text-ink-blue/50 font-brand uppercase tracking-wide mb-3">
            {@popup_question.criterion_name}
          </div>
        <% end %>

        <p class="text-ink-blue/70 text-sm whitespace-pre-line leading-relaxed">
          {format_description(@popup_question.explanation)}
        </p>

        <%= if length(@popup_question.discussion_prompts) > 0 do %>
          <div class="mt-4 pt-4 border-t border-ink-blue/10">
            <h3 class="text-xs font-semibold text-accent-purple uppercase tracking-wide mb-2">
              Discussion Tips
            </h3>
            <ul class="space-y-1.5">
              <%= for prompt <- @popup_question.discussion_prompts do %>
                <li class="flex gap-2 text-ink-blue/60 text-sm">
                  <span class="text-accent-purple shrink-0">•</span>
                  <span>{prompt}</span>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>

        <div class="mt-4 text-center">
          <button
            type="button"
            phx-click="close_criterion_info"
            class="text-sm text-ink-blue/50 hover:text-ink-blue transition-colors font-brand"
          >
            Close
          </button>
        </div>
      </.sheet>
    </div>
    """
  end

  # ═══════════════════════════════════════════════════════════════════════════
  # Score Input Overlay
  # ═══════════════════════════════════════════════════════════════════════════

  defp render_score_overlay(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 flex items-center justify-center score-overlay-enter" data-no-navigate>
      <!-- Backdrop -->
      <div class="absolute inset-0 bg-ink-blue/30 backdrop-blur-sm" phx-click="close_score_overlay">
      </div>
      <!-- Modal -->
      <.sheet class="shadow-sheet-lifted p-4 max-w-sm w-full mx-4 relative">
        <h3 class="font-workshop text-lg font-bold text-ink-blue text-center mb-1">
          {@current_question.title}
        </h3>

        <div class="text-center mb-3">
          <div class="text-traffic-green text-base font-semibold font-brand">
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
          <p class="text-center text-ink-blue/60 text-sm mt-2">
            Discuss this score, then click "Done" when ready
          </p>
        <% end %>
      </.sheet>
    </div>
    """
  end

  defp render_balance_scale(assigns) do
    ~H"""
    <div class="space-y-2">
      <div class="flex justify-between text-xs text-ink-blue/60">
        <span>Too little</span>
        <span>Just right</span>
        <span>Too much</span>
      </div>

      <div class="flex gap-0.5">
        <%= for v <- -5..5 do %>
          <button
            type="button"
            phx-click="select_score"
            phx-value-score={v}
            class={[
              "flex-1 min-w-0 py-2 rounded-md font-semibold text-xs transition-all cursor-pointer font-workshop",
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
    <div class="space-y-2">
      <div class="flex justify-between text-xs text-ink-blue/60">
        <span>Low</span>
        <span>High</span>
      </div>

      <div class="flex gap-0.5">
        <%= for v <- 0..10 do %>
          <button
            type="button"
            phx-click="select_score"
            phx-value-score={v}
            class={[
              "flex-1 min-w-0 py-2 rounded-md font-semibold text-xs transition-all cursor-pointer font-workshop",
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
