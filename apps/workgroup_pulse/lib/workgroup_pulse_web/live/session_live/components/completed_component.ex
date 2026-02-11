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
  alias WorkgroupPulseWeb.SessionLive.Components.ExportPrintComponent

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :participants, :list, required: true
  attr :scores_summary, :list, required: true
  attr :individual_scores, :map, required: true
  attr :strengths, :list, required: true
  attr :concerns, :list, required: true
  attr :all_notes, :list, required: true
  attr :all_actions, :list, required: true
  attr :action_count, :integer, required: true
  attr :action_input, :string, required: true
  attr :show_export_modal, :boolean, required: true
  attr :export_report_type, :string, required: true
  attr :summary_template, :map, required: true

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
          Cumulative Team Score
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
            <div class="bg-accent-red/5 border border-accent-red/30 rounded-lg p-3">
              <h3 class="text-sm font-semibold text-accent-red mb-2 font-brand">
                Areas of Concern ({length(@concerns)})
              </h3>
              <ul class="space-y-1.5">
                <%= for item <- @concerns do %>
                  <li class="flex items-center gap-2 text-sm text-ink-blue/70">
                    <span class="text-accent-red text-xs">!</span>
                    <span class="font-workshop">{item.title}</span>
                    <span class="text-accent-red font-semibold ml-auto font-workshop text-sm">
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
      <div class="bg-accent-magenta/5 border border-accent-magenta/30 rounded-lg p-3 mb-5">
        <h3 class="text-sm font-semibold text-accent-magenta mb-2 font-brand">
          Action Items
          <%= if @action_count > 0 do %>
            ({@action_count})
          <% end %>
        </h3>

        <form phx-submit="add_action" class="mb-2">
          <input
            type="text"
            name="action"
            value={@action_input}
            phx-change="update_action_input"
            phx-debounce="300"
            placeholder="Add an action item..."
            class="w-full bg-surface-sheet border border-ink-blue/10 rounded-lg px-3 py-2 text-sm text-ink-blue placeholder-ink-blue/40 focus:outline-none focus:border-accent-magenta focus:ring-1 focus:ring-accent-magenta font-workshop"
          />
        </form>

        <%= if @action_count > 0 do %>
          <ul class="space-y-1.5">
            <%= for action <- @all_actions do %>
              <li class="flex items-start gap-2 text-sm text-ink-blue/70 group">
                <span class="text-accent-magenta text-xs mt-0.5">→</span>
                <span class="font-workshop flex-1">{action.description}</span>
                <button
                  type="button"
                  phx-click="delete_action"
                  phx-value-id={action.id}
                  class="text-ink-blue/30 hover:text-traffic-red transition-colors opacity-0 group-hover:opacity-100 shrink-0"
                >
                  ✕
                </button>
              </li>
            <% end %>
          </ul>
        <% else %>
          <p class="text-ink-blue/50 text-sm italic font-workshop">
            No action items yet. Type above to add one.
          </p>
        <% end %>
      </div>

      <%!-- Export --%>
      <ExportModalComponent.render
        show_export_modal={@show_export_modal}
        export_report_type={@export_report_type}
      />

      <%!-- Finish Workshop (facilitator only) --%>
      <%= if @participant.is_facilitator do %>
        <div class="mt-5 pt-4 border-t border-ink-blue/10 text-center">
          <button
            phx-click="finish_workshop"
            class="btn-workshop btn-workshop-primary"
          >
            Finish Workshop
          </button>
        </div>
      <% end %>
    </.sheet>

    <%!-- Hidden print div for PDF export --%>
    <ExportPrintComponent.render
      export_report_type={@export_report_type}
      session={@session}
      participants={@participants}
      scores_summary={@scores_summary}
      individual_scores={@individual_scores}
      strengths={@strengths}
      concerns={@concerns}
      all_notes={@all_notes}
      all_actions={@all_actions}
      summary_template={@summary_template}
    />
    """
  end
end
