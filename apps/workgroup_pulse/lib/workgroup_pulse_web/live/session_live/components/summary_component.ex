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
  attr :all_questions, :list, required: true

  def render(assigns) do
    ~H"""
    <.sheet class="shadow-sheet p-sheet-padding w-[960px] h-full">
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
        <GridHelpers.scoring_grid
          all_questions={@all_questions}
          participants={@participants}
          scores={@individual_scores}
        >
          <:cell :let={%{question: q, score_data: sd}}>
            <td class={[
              "score-cell",
              sd && cell_color_class(sd.color)
            ]}>
              <%= if sd do %>
                <span class={["font-bold font-workshop", text_color_class(sd.color)]}>
                  {GridHelpers.format_score_value(q.scale_type, sd.value)}
                </span>
              <% else %>
                <span class="text-ink-blue/30">—</span>
              <% end %>
            </td>
          </:cell>
        </GridHelpers.scoring_grid>
      <% end %>
    </.sheet>
    """
  end

  # Inset colour for table cells — ring-inset uses box-shadow so it doesn't
  # expand the cell or clip neighbouring borders.
  defp cell_color_class(:green), do: "bg-green-100 ring-2 ring-inset ring-traffic-green"
  defp cell_color_class(:amber), do: "bg-amber-100 ring-2 ring-inset ring-amber-500"
  defp cell_color_class(:red), do: "bg-red-100 ring-2 ring-inset ring-traffic-red"
  defp cell_color_class(_), do: "bg-gray-100 ring-2 ring-inset ring-gray-300"
end
