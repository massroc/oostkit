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
      class="p-2 w-[960px] h-full shadow-sheet-lifted transition-all duration-300"
      phx-click="focus_sheet"
      phx-value-sheet="main"
    >
      <!-- Full Scoring Grid -->
      <%= if length(@all_questions) > 0 do %>
        <GridHelpers.scoring_grid
          all_questions={@all_questions}
          participants={@participants}
          scores={@all_questions_scores}
          active_participant_id={@current_turn_participant_id}
          active_question_index={@current_question.index}
          criterion_click_event="show_criterion_info"
        >
          <:cell :let={%{question: q, participant: p, score_data: sd}}>
            <.score_cell
              question={q}
              participant={p}
              score_data={sd}
              session={@session}
              current_question={@current_question}
              my_participant={@participant}
              is_my_turn={@is_my_turn}
              current_turn_participant_id={@current_turn_participant_id}
              my_turn_locked={@my_turn_locked}
              has_submitted={@has_submitted}
            />
          </:cell>
        </GridHelpers.scoring_grid>
      <% end %>
    </.sheet>
    """
  end

  attr :question, :map, required: true
  attr :participant, :map, required: true
  attr :score_data, :any, default: nil
  attr :session, :map, required: true
  attr :current_question, :map, required: true
  attr :my_participant, :map, required: true
  attr :is_my_turn, :boolean, required: true
  attr :current_turn_participant_id, :any, required: true
  attr :my_turn_locked, :boolean, required: true
  attr :has_submitted, :boolean, required: true

  defp score_cell(assigns) do
    is_current = assigns.question.index == assigns.current_question.index
    is_past = assigns.question.index < assigns.session.current_question_index
    is_future = assigns.question.index > assigns.session.current_question_index

    can_interact =
      is_current and assigns.participant.id == assigns.my_participant.id and
        assigns.is_my_turn and not assigns.my_turn_locked

    can_skip =
      is_current and assigns.my_participant.is_facilitator and
        assigns.participant.id == assigns.current_turn_participant_id and
        assigns.participant.id != assigns.my_participant.id and
        not has_score?(assigns.score_data)

    assigns =
      assigns
      |> assign(:is_current, is_current)
      |> assign(:is_past, is_past)
      |> assign(:is_future, is_future)
      |> assign(:can_interact, can_interact)
      |> assign(:can_skip, can_skip)

    ~H"""
    <td
      class={[
        "score-cell",
        @is_current && @participant.id == @current_turn_participant_id && "active-col",
        not @is_current && @participant.id == @current_turn_participant_id && "active-col",
        @can_interact && "cursor-pointer hover:bg-accent-purple-light",
        @can_interact && not @has_submitted && "outline outline-2 outline-accent-purple rounded",
        @can_skip && "cursor-pointer"
      ]}
      phx-click={
        cond do
          @can_interact -> "edit_my_score"
          @can_skip -> "skip_turn"
          true -> nil
        end
      }
    >
      <%= cond do %>
        <% @can_interact and not @has_submitted -> %>
          <span class="text-[11px] leading-tight text-accent-purple font-workshop block">
            Click to<br />score
          </span>
        <% @can_skip -> %>
          <span class="text-[11px] leading-tight text-accent-purple font-workshop block">
            Skip<br />turn
          </span>
        <% true -> %>
          {render_score_value(assigns)}
      <% end %>
    </td>
    """
  end

  defp render_score_value(%{is_future: true}), do: "—"

  defp render_score_value(%{is_past: true, score_data: %{has_score: true, value: value}} = assigns) do
    GridHelpers.format_score_value(assigns.question.scale_type, value)
  end

  defp render_score_value(%{is_past: true}), do: "?"

  defp render_score_value(
         %{is_current: true, score_data: %{has_score: true, value: value}} = assigns
       ) do
    GridHelpers.format_score_value(assigns.question.scale_type, value)
  end

  defp render_score_value(%{
         is_current: true,
         current_turn_participant_id: turn_id,
         participant: %{id: pid}
       })
       when pid == turn_id,
       do: "..."

  defp render_score_value(%{is_current: true}), do: "—"
  defp render_score_value(_assigns), do: "—"

  defp has_score?(%{has_score: true}), do: true
  defp has_score?(_), do: false
end
