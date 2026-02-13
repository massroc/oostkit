defmodule WorkgroupPulseWeb.SessionLive.GridHelpers do
  @moduledoc """
  Shared helpers and components for scoring grid rendering used by both
  ScoringComponent and SummaryComponent.
  """

  use Phoenix.Component

  # Fixed number of participant column slots to maintain consistent grid width
  @grid_participant_slots 10

  # Questions that are first of a paired criterion — emit a header row before them
  @first_of_pair MapSet.new(["2a", "5a"])

  @doc """
  Returns the sub-label ("a" or "b") for paired criteria, nil otherwise.
  """
  def sub_label(question) do
    cn = question.criterion_number

    cond do
      String.ends_with?(cn, "a") -> "a"
      String.ends_with?(cn, "b") -> "b"
      true -> nil
    end
  end

  @doc """
  Returns true if this question starts a paired criterion group.
  """
  def first_of_pair?(criterion_number) do
    MapSet.member?(@first_of_pair, criterion_number)
  end

  @doc """
  Prepares common grid assigns: active_participants, balance/maximal question
  splits, empty_slots, total_cols.
  """
  def prepare_grid_assigns(assigns) do
    active_participants =
      Enum.filter(assigns.participants, fn p -> not p.is_observer end)

    balance_questions = Enum.filter(assigns.all_questions, &(&1.scale_type == "balance"))
    maximal_questions = Enum.filter(assigns.all_questions, &(&1.scale_type == "maximal"))

    empty_slots = max(@grid_participant_slots - length(active_participants), 0)
    total_cols = 1 + length(active_participants) + empty_slots

    assigns
    |> assign(:active_participants, active_participants)
    |> assign(:balance_questions, balance_questions)
    |> assign(:maximal_questions, maximal_questions)
    |> assign(:empty_slots, empty_slots)
    |> assign(:total_cols, total_cols)
  end

  @doc """
  Formats a score value for display. Balance values > 0 get a + prefix.
  """
  def format_score_value("balance", value) when value > 0, do: "+#{value}"
  def format_score_value(_, value), do: "#{value}"

  @doc """
  Formats a criterion title, wrapping long titles like "Mutual Support and Respect".
  """
  def format_criterion_title("Mutual Support and Respect") do
    Phoenix.HTML.raw("Mutual Support<br/><span style=\"padding-left:8px\">and Respect</span>")
  end

  def format_criterion_title(title), do: title

  # ---------------------------------------------------------------------------
  # Shared scoring grid component
  # ---------------------------------------------------------------------------

  @doc """
  Renders the shared scoring grid table structure with scale labels,
  criterion headers, and participant columns.

  Each component provides its own cell rendering via the `:cell` slot,
  which receives `%{question: question, participant: participant, score_data: data}`.

  ## Attributes

    * `:all_questions` - List of all question structs
    * `:participants` - List of all participant structs (observers will be filtered)
    * `:scores` - Map of `%{question_index => [%{participant_id: _, ...}]}`
    * `:active_participant_id` - Highlights this participant's column header (optional)
    * `:active_question_index` - Adds "active-row" class to this question's row (optional)
    * `:criterion_click_event` - Event name for criterion cell clicks (optional)

  """
  attr :all_questions, :list, required: true
  attr :participants, :list, required: true
  attr :scores, :map, required: true
  attr :active_participant_id, :any, default: nil
  attr :active_question_index, :any, default: nil
  attr :criterion_click_event, :string, default: nil

  slot :cell, required: true

  def scoring_grid(assigns) do
    assigns = prepare_grid_assigns(assigns)

    balance_rows = Enum.map(assigns.balance_questions, &build_row_data(assigns, &1))
    maximal_rows = Enum.map(assigns.maximal_questions, &build_row_data(assigns, &1))

    assigns =
      assign(assigns, :scale_sections, [
        {"Balance Scale (-5 to +5)", balance_rows},
        {"Maximal Scale (0 to 10)", maximal_rows}
      ])

    ~H"""
    <table class="scoring-grid">
      <thead>
        <tr>
          <th class="criterion-col"></th>
          <%= for p <- @active_participants do %>
            <th class={[
              "participant-col",
              p.id == @active_participant_id && "active-col-header"
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
        <%= for {scale_label, rows} <- @scale_sections do %>
          <tr>
            <td class="scale-label" colspan={@total_cols}>
              {scale_label}
            </td>
          </tr>
          <%= for row <- rows do %>
            <%= if row.is_first_of_pair do %>
              <tr>
                <td class="criterion-group-header" colspan={@total_cols}>
                  {row.question.criterion_name}
                </td>
              </tr>
            <% end %>
            <tr class={row.question.index == @active_question_index && "active-row"}>
              <td
                class={[
                  "criterion",
                  row.sub_label && "criterion-indented",
                  @criterion_click_event &&
                    "cursor-pointer hover:bg-accent-purple-light/50 transition-colors"
                ]}
                phx-click={@criterion_click_event}
                phx-value-index={@criterion_click_event && row.question.index}
              >
                <span class="name">
                  <%= if row.sub_label do %>
                    <span style="text-transform: lowercase">{row.sub_label}.</span>
                    {format_criterion_title(row.question.title)}
                  <% else %>
                    {format_criterion_title(row.question.title)}
                  <% end %>
                </span>
              </td>
              <%= for p <- @active_participants do %>
                {render_slot(@cell, %{
                  question: row.question,
                  participant: p,
                  score_data: Map.get(row.scores_by_participant, p.id)
                })}
              <% end %>
              <%= for _ <- 1..@empty_slots//1 do %>
                <td class="score-cell"></td>
              <% end %>
            </tr>
          <% end %>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp build_row_data(assigns, question) do
    question_scores = Map.get(assigns.scores, question.index, [])

    %{
      question: question,
      scores_by_participant: Map.new(question_scores, &{&1.participant_id, &1}),
      is_first_of_pair: first_of_pair?(question.criterion_number),
      sub_label: sub_label(question)
    }
  end
end
