defmodule WorkgroupPulseWeb.SessionLive.Components.CompletedComponent do
  @moduledoc """
  Renders the completed/wrap-up phase as a sheet in the carousel.
  Shows final scores, strengths, concerns, action items, and export options.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]

  import WorkgroupPulseWeb.SessionLive.ScoreHelpers,
    only: [text_color_class: 1, card_color_class: 1]

  alias WorkgroupPulseWeb.SessionLive.Components.ExportModalComponent

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :scores_summary, :list, required: true
  attr :strengths, :list, required: true
  attr :concerns, :list, required: true
  attr :all_actions, :list, required: true
  attr :action_count, :integer, required: true
  attr :show_export_modal, :boolean, required: true
  attr :export_content, :string, required: true

  def render(assigns) do
    ~H"""
    <.sheet class="shadow-sheet p-sheet-padding w-[720px] h-full">
      <%!-- Header --%>
      <div class="text-center mb-5 pb-3 border-b border-ink-blue/10">
        <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-1">
          Workshop Wrap-Up
        </h1>
        <p class="text-ink-blue/60 text-sm font-brand">
          Review key findings and create action items.
        </p>
        <p class="text-xs text-ink-blue/40 mt-1.5 font-brand">
          Session <span class="font-mono text-ink-blue/70 tracking-wider">{@session.code}</span>
        </p>
      </div>

      <%!-- Score Grid --%>
      <div class="bg-surface-wall/50 rounded-lg p-3 mb-5">
        <h2 class="text-xs font-semibold text-ink-blue/50 mb-2 font-brand uppercase tracking-wide">
          All Scores
        </h2>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
          <%= for score <- @scores_summary do %>
            <div class={["rounded-md p-2.5 text-center border", card_color_class(score.color)]}>
              <div class="text-[10px] text-ink-blue/40 mb-0.5 font-brand">
                Q{score.question_index + 1}
              </div>
              <div class={["text-xl font-bold font-workshop", text_color_class(score.color)]}>
                <%= if score.combined_team_value do %>
                  {round(score.combined_team_value)}/10
                <% else %>
                  —
                <% end %>
              </div>
              <div
                class="text-[10px] text-ink-blue/50 truncate mt-0.5 font-workshop"
                title={score.title}
              >
                {score.title}
              </div>
            </div>
          <% end %>
        </div>
        <div class="flex items-center justify-center gap-1 text-[10px] text-ink-blue/35 mt-2 font-brand">
          <span>Combined Team Values</span>
          <span
            class="cursor-help"
            title="Each person's score is graded (green=2, amber=1, red=0), then averaged and scaled to 0-10. 10 = everyone scored well, 0 = everyone scored poorly."
          >
            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </span>
        </div>
      </div>

      <%!-- Pattern Highlighting --%>
      <%= if length(@strengths) > 0 or length(@concerns) > 0 do %>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-3 mb-5">
          <%!-- Strengths --%>
          <%= if length(@strengths) > 0 do %>
            <div class="bg-traffic-green/5 border border-traffic-green/30 rounded-lg p-3">
              <h3 class="text-sm font-semibold text-traffic-green mb-2 font-brand">
                Strengths ({length(@strengths)})
              </h3>
              <ul class="space-y-1.5">
                <%= for item <- @strengths do %>
                  <li class="flex items-center gap-2 text-sm text-ink-blue/70">
                    <span class="text-traffic-green text-xs">✓</span>
                    <span class="font-workshop">{item.title}</span>
                    <span class="text-traffic-green font-semibold ml-auto font-workshop text-sm">
                      {round(item.combined_team_value)}/10
                    </span>
                  </li>
                <% end %>
              </ul>
            </div>
          <% end %>

          <%!-- Concerns --%>
          <%= if length(@concerns) > 0 do %>
            <div class="bg-traffic-red/5 border border-traffic-red/30 rounded-lg p-3">
              <h3 class="text-sm font-semibold text-traffic-red mb-2 font-brand">
                Areas of Concern ({length(@concerns)})
              </h3>
              <ul class="space-y-1.5">
                <%= for item <- @concerns do %>
                  <li class="flex items-center gap-2 text-sm text-ink-blue/70">
                    <span class="text-traffic-red text-xs">!</span>
                    <span class="font-workshop">{item.title}</span>
                    <span class="text-traffic-red font-semibold ml-auto font-workshop text-sm">
                      {round(item.combined_team_value)}/10
                    </span>
                  </li>
                <% end %>
              </ul>
            </div>
          <% end %>
        </div>
      <% end %>

      <%!-- Actions --%>
      <%= if length(@all_actions) > 0 do %>
        <div class="bg-accent-purple/5 border border-accent-purple/30 rounded-lg p-3 mb-5">
          <h3 class="text-sm font-semibold text-accent-purple mb-2 font-brand">
            Action Items ({length(@all_actions)})
          </h3>
          <ul class="space-y-1.5">
            <%= for action <- @all_actions do %>
              <li class="flex items-start gap-2 text-sm text-ink-blue/70">
                <span class="text-accent-purple text-xs mt-0.5">→</span>
                <span class="font-workshop flex-1">{action.description}</span>
                <%= if action.owner_name do %>
                  <span class="text-[10px] text-ink-blue/40 font-brand whitespace-nowrap">
                    {action.owner_name}
                  </span>
                <% end %>
              </li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <%!-- Export --%>
      <ExportModalComponent.render
        show_export_modal={@show_export_modal}
        export_content={@export_content}
        action_count={@action_count}
      />
    </.sheet>
    """
  end
end
