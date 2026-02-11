defmodule WorkgroupPulseWeb.SessionLive.Components.ScoringComponent do
  @moduledoc """
  Renders the scoring phase as a sheet in the carousel.
  Features the full 8-question grid with the mid-transition interstitial.
  Score overlays, floating buttons, and notes panel are separate components.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]

  alias WorkgroupPulseWeb.SessionLive.GridHelpers

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :participants, :list, required: true
  attr :current_question, :map, required: true
  attr :has_submitted, :boolean, required: true
  attr :is_my_turn, :boolean, required: true
  attr :current_turn_participant_id, :any, required: true
  attr :my_turn_locked, :boolean, required: true
  attr :show_mid_transition, :boolean, required: true
  attr :all_questions, :list, required: true
  attr :all_questions_scores, :map, required: true

  def render(assigns) do
    ~H"""
    <!-- Main Sheet with scoring grid -->
    <.sheet
      class="p-3 w-[960px] h-full shadow-sheet-lifted transition-all duration-300"
      phx-click="focus_sheet"
      phx-value-sheet="main"
    >
      <!-- Full Scoring Grid -->
      <%= if length(@all_questions) > 0 do %>
        {render_full_scoring_grid(assigns)}
      <% end %>
    </.sheet>
    """
  end

  defp render_full_scoring_grid(assigns) do
    assigns = GridHelpers.prepare_grid_assigns(assigns)

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

    is_first_of_pair = GridHelpers.first_of_pair?(question.criterion_number)
    label = GridHelpers.sub_label(question)

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
            <span style="text-transform: lowercase">{@sub_label}.</span> {GridHelpers.format_criterion_title(
              @question.title
            )}
          <% else %>
            {GridHelpers.format_criterion_title(@question.title)}
          <% end %>
        </span>
      </td>
      <%= for p <- @active_participants do %>
        <% score_data = Map.get(@question_scores_by_participant, p.id) %>
        <% can_interact =
          @is_current and p.id == @participant.id and @is_my_turn and not @my_turn_locked %>
        <% can_skip =
          @is_current and @participant.is_facilitator and
            p.id == @current_turn_participant_id and p.id != @participant.id and
            not has_score?(score_data) %>
        <td
          class={[
            "score-cell",
            @is_current && p.id == @current_turn_participant_id && "active-col",
            not @is_current && p.id == @current_turn_participant_id && "active-col",
            can_interact && "cursor-pointer hover:bg-accent-purple-light",
            can_interact && not @has_submitted && "outline outline-2 outline-accent-purple rounded",
            can_skip && "cursor-pointer"
          ]}
          phx-click={
            cond do
              can_interact -> "edit_my_score"
              can_skip -> "skip_turn"
              true -> nil
            end
          }
        >
          <%= cond do %>
            <% can_interact and not @has_submitted -> %>
              <span class="text-[11px] leading-tight text-accent-purple font-workshop block">
                Click to<br />score
              </span>
            <% can_skip -> %>
              <span class="text-[11px] leading-tight text-accent-purple font-workshop block">
                Skip<br />turn
              </span>
            <% true -> %>
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
    GridHelpers.format_score_value(assigns.question.scale_type, value)
  end

  defp render_score_cell_value(%{is_past: true}, _score_data, _participant_id), do: "?"

  # Current question with score - show it
  defp render_score_cell_value(%{is_current: true} = assigns, %{has_score: true, value: value}, _) do
    GridHelpers.format_score_value(assigns.question.scale_type, value)
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

  defp has_score?(%{has_score: true}), do: true
  defp has_score?(_), do: false
end
