defmodule WorkgroupPulseWeb.SessionLive.Components.SummaryComponent do
  @moduledoc """
  Renders the summary phase as a sheet in the carousel.
  Shows a read-only scoring grid with traffic-light coloured cells.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]

  import WorkgroupPulseWeb.SessionLive.ScoreHelpers,
    only: [text_color_class: 1, bg_color_class: 1]

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

  defp render_summary_grid(assigns) do
    active_participants =
      Enum.filter(assigns.participants, fn p -> not p.is_observer end)

    balance_questions = Enum.filter(assigns.all_questions, &(&1.scale_type == "balance"))
    maximal_questions = Enum.filter(assigns.all_questions, &(&1.scale_type == "maximal"))

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

    is_first_of_pair = MapSet.member?(@first_of_pair, question.criterion_number)
    label = sub_label(question)

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
            <span style="text-transform: lowercase">{@sub_label}.</span> {format_criterion_title(
              @question.title
            )}
          <% else %>
            {format_criterion_title(@question.title)}
          <% end %>
        </span>
      </td>
      <%= for p <- @active_participants do %>
        <% score_data = Map.get(@scores_by_participant, p.id) %>
        <td class={[
          "score-cell",
          score_data && bg_color_class(score_data.color)
        ]}>
          <%= if score_data do %>
            <span class={["font-bold font-workshop", text_color_class(score_data.color)]}>
              {format_score_value(@question.scale_type, score_data.value)}
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

  defp format_score_value("balance", value) when value > 0, do: "+#{value}"
  defp format_score_value(_, value), do: "#{value}"

  defp format_criterion_title("Mutual Support and Respect") do
    Phoenix.HTML.raw("Mutual Support<br/><span style=\"padding-left:8px\">and Respect</span>")
  end

  defp format_criterion_title(title), do: title
end
