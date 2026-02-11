defmodule WorkgroupPulseWeb.SessionLive.Components.SummaryComponent do
  @moduledoc """
  Renders the summary phase as a sheet in the carousel.
  Shows a read-only scoring grid with traffic-light coloured cells.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]

  import WorkgroupPulseWeb.SessionLive.ScoreHelpers,
    only: [text_color_class: 1]

  alias WorkgroupPulseWeb.SessionLive.GridHelpers

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :participants, :list, required: true
  attr :scores_summary, :list, required: true
  attr :individual_scores, :map, required: true
  attr :notes_by_question, :map, required: true
  attr :all_questions, :list, required: true

  def render(assigns) do
    ~H"""
    <.sheet class="shadow-sheet p-sheet-padding w-[720px] h-full">
      <%!-- Header --%>
      <div class="text-center mb-5 pb-3 border-b border-ink-blue/10">
        <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-1">
          Workshop Summary
        </h1>
        <p class="text-ink-blue/60 text-sm font-brand">
          Review your team's responses before creating action items.
        </p>
      </div>

      <%!-- Scoring Grid --%>
      <%= if length(@all_questions) > 0 do %>
        {render_summary_grid(assigns)}
      <% end %>
    </.sheet>
    """
  end

  defp render_summary_grid(assigns) do
    assigns = GridHelpers.prepare_grid_assigns(assigns)

    ~H"""
    <table class="scoring-grid">
      <thead>
        <tr>
          <th class="criterion-col"></th>
          <%= for p <- @active_participants do %>
            <th class="participant-col">
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
        <!-- Balance questions -->
        <%= for q <- @balance_questions do %>
          {render_question_row(assigns, q)}
        <% end %>
        <!-- Scale label: Maximal -->
        <tr>
          <td class="scale-label" colspan={@total_cols}>
            Maximal Scale (0 to 10)
          </td>
        </tr>
        <!-- Maximal questions -->
        <%= for q <- @maximal_questions do %>
          {render_question_row(assigns, q)}
        <% end %>
      </tbody>
    </table>
    """
  end

  defp render_question_row(assigns, question) do
    # Get individual scores for this question
    question_scores = Map.get(assigns.individual_scores, question.index, [])

    # Build a map of participant_id -> score data for this question
    scores_by_participant = Map.new(question_scores, &{&1.participant_id, &1})

    is_first_of_pair = GridHelpers.first_of_pair?(question.criterion_number)
    label = GridHelpers.sub_label(question)

    assigns =
      assigns
      |> assign(:question, question)
      |> assign(:scores_by_participant, scores_by_participant)
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
    <tr>
      <td class={[
        "criterion",
        @sub_label && "criterion-indented"
      ]}>
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
        <% score_data = Map.get(@scores_by_participant, p.id) %>
        <td class={[
          "score-cell",
          score_data && cell_color_class(score_data.color)
        ]}>
          <%= if score_data do %>
            <span class={["font-bold font-workshop", text_color_class(score_data.color)]}>
              {GridHelpers.format_score_value(@question.scale_type, score_data.value)}
            </span>
          <% else %>
            <span class="text-ink-blue/30">—</span>
          <% end %>
        </td>
      <% end %>
      <%= for _ <- 1..@empty_slots//1 do %>
        <td class="score-cell"></td>
      <% end %>
    </tr>
    """
  end

  # Inset colour for table cells — ring-inset uses box-shadow so it doesn't
  # expand the cell or clip neighbouring borders.
  defp cell_color_class(:green), do: "bg-green-100 ring-2 ring-inset ring-traffic-green"
  defp cell_color_class(:amber), do: "bg-amber-100 ring-2 ring-inset ring-amber-500"
  defp cell_color_class(:red), do: "bg-red-100 ring-2 ring-inset ring-traffic-red"
  defp cell_color_class(_), do: "bg-gray-100 ring-2 ring-inset ring-gray-300"
end
