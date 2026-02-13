defmodule WorkgroupPulseWeb.SessionLive.Components.ScoreOverlayComponent do
  @moduledoc """
  Renders the score input overlay and criterion info popup.
  These MUST remain outside the carousel container in the DOM because
  CSS transform breaks position:fixed.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]
  import WorkgroupPulseWeb.SessionLive.ScoreHelpers, only: [format_description: 1]

  attr :session, :map, required: true
  attr :is_my_turn, :boolean, required: true
  attr :my_turn_locked, :boolean, required: true
  attr :show_score_overlay, :boolean, required: true
  attr :show_discuss_prompt, :boolean, required: true
  attr :show_team_discuss_prompt, :boolean, required: true
  attr :show_criterion_popup, :any, required: true
  attr :current_question, :map, required: true
  attr :selected_value, :any, required: true
  attr :has_submitted, :boolean, required: true
  attr :all_questions, :list, required: true

  def render(assigns) do
    ~H"""
    <%= if @session.state in ["scoring", "summary", "completed"] do %>
      <!-- Score Input Overlay -->
      <%= if @is_my_turn and not @my_turn_locked and @show_score_overlay do %>
        {render_score_overlay(assigns)}
      <% end %>
      <!-- Discuss Prompt (after score submitted) -->
      <%= if @show_discuss_prompt and not @show_score_overlay do %>
        {render_discuss_prompt(assigns)}
      <% end %>
      <!-- Team Discuss Prompt (all turns complete) -->
      <%= if @show_team_discuss_prompt and not @show_score_overlay and not @show_discuss_prompt do %>
        {render_team_discuss_prompt(assigns)}
      <% end %>
      <!-- Criterion Info Popup -->
      <%= if @show_criterion_popup != nil do %>
        {render_criterion_popup(assigns)}
      <% end %>
    <% end %>
    """
  end

  defp render_score_overlay(assigns) do
    ~H"""
    <div class="fixed inset-0 z-modal flex items-center justify-center score-overlay-enter">
      <!-- Backdrop -->
      <div class="absolute inset-0 bg-ink-blue/30 backdrop-blur-sm" phx-click="close_score_overlay">
      </div>
      <!-- Modal -->
      <.sheet class="shadow-sheet-lifted p-5 max-w-md w-full mx-4 relative">
        <h3 class="font-workshop text-xl font-bold text-ink-blue text-center mb-1">
          {@current_question.title}
        </h3>

        <div class="text-center mb-3">
          <div class="text-accent-gold text-lg font-semibold font-brand">
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
          <p class="text-center text-ink-blue/60 text-base mt-2">
            Discuss this score, then click "Done" when ready
          </p>
        <% end %>
      </.sheet>
    </div>
    """
  end

  defp render_discuss_prompt(assigns) do
    ~H"""
    <div
      class="fixed inset-0 z-50 flex items-center justify-center score-overlay-enter"
      phx-click="dismiss_discuss_prompt"
    >
      <!-- Backdrop -->
      <div class="absolute inset-0 bg-ink-blue/20 backdrop-blur-[2px]"></div>
      <!-- Prompt -->
      <.sheet class="shadow-sheet-lifted px-8 py-6 relative">
        <p class="font-workshop text-2xl font-bold text-ink-blue text-center">
          Discuss your score
        </p>
        <p class="text-ink-blue/50 text-sm font-brand text-center mt-1">
          Click anywhere to dismiss
        </p>
      </.sheet>
    </div>
    """
  end

  defp render_team_discuss_prompt(assigns) do
    ~H"""
    <div
      class="fixed inset-0 z-50 flex items-center justify-center score-overlay-enter"
      phx-click="dismiss_team_discuss_prompt"
    >
      <!-- Backdrop -->
      <div class="absolute inset-0 bg-ink-blue/20 backdrop-blur-[2px]"></div>
      <!-- Prompt -->
      <.sheet class="shadow-sheet-lifted px-8 py-6 relative">
        <p class="font-workshop text-2xl font-bold text-ink-blue text-center">
          Discuss the scores as a team
        </p>
        <p class="text-ink-blue/50 text-sm font-brand text-center mt-1">
          Click anywhere to dismiss
        </p>
      </.sheet>
    </div>
    """
  end

  defp render_balance_scale(assigns) do
    ~H"""
    <div class="space-y-2">
      <div class="flex justify-between text-sm text-ink-blue/60">
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
              "flex-1 min-w-0 py-3.5 rounded-md font-semibold text-lg transition-all cursor-pointer font-workshop",
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

      <div class="flex justify-between text-sm text-ink-blue/50">
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
      <div class="flex justify-between text-sm text-ink-blue/60">
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
              "flex-1 min-w-0 py-3.5 rounded-md font-semibold text-lg transition-all cursor-pointer font-workshop",
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

      <div class="flex justify-between text-sm text-ink-blue/50">
        <span>0</span>
        <span>10</span>
      </div>
    </div>
    """
  end

  defp render_criterion_popup(assigns) do
    popup_question =
      Enum.find(assigns.all_questions, fn q -> q.index == assigns.show_criterion_popup end)

    assigns = assign(assigns, :popup_question, popup_question)

    ~H"""
    <div class="fixed inset-0 z-modal flex items-center justify-center score-overlay-enter">
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
            <h3 class="text-xs font-semibold text-accent-magenta uppercase tracking-wide mb-2">
              Discussion Tips
            </h3>
            <ul class="space-y-1.5">
              <%= for prompt <- @popup_question.discussion_prompts do %>
                <li class="flex gap-2 text-ink-blue/60 text-sm">
                  <span class="text-accent-magenta shrink-0">•</span>
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
end
