defmodule WorkgroupPulseWeb.SessionLive.Components.ExportModalComponent do
  @moduledoc """
  Renders the export button and modal for downloading workshop results.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import OostkitShared.Components, only: [icon: 1]

  attr :show_export_modal, :boolean, required: true
  attr :export_report_type, :string, required: true

  def render(assigns) do
    ~H"""
    <div>
      <%!-- Export Button --%>
      <div id="export-container" phx-hook="ExportHook">
        <button
          type="button"
          phx-click="toggle_export_modal"
          class="w-full btn-workshop btn-workshop-primary py-2.5 flex items-center justify-center gap-2"
        >
          <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
          <span>Export Results</span>
        </button>
      </div>

      <%!-- Export Modal --%>
      <%= if @show_export_modal do %>
        <div
          class="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
          phx-click-away="close_export_modal"
        >
          <div class="bg-surface-sheet rounded-sheet shadow-sheet-lifted p-sheet-padding max-w-sm w-full mx-4">
            <div class="flex items-center justify-between mb-3">
              <h3 class="font-workshop text-xl font-bold text-ink-blue">Export Report</h3>
              <button
                type="button"
                phx-click="close_export_modal"
                class="text-ink-blue/30 hover:text-ink-blue/60 transition-colors"
              >
                <.icon name="hero-x-mark" class="w-5 h-5" />
              </button>
            </div>

            <p class="text-ink-blue/60 text-xs font-brand mb-4">
              Choose a report type and format.
            </p>

            <div class="space-y-2 mb-4">
              <label class={[
                "flex items-center gap-3 p-2.5 rounded-lg cursor-pointer transition-all border",
                if(@export_report_type == "full",
                  do: "bg-accent-purple/10 border-accent-purple",
                  else: "bg-surface-wall border-ink-blue/10 hover:border-ink-blue/20"
                )
              ]}>
                <input
                  type="radio"
                  name="export_report_type"
                  value="full"
                  checked={@export_report_type == "full"}
                  phx-click="select_export_report_type"
                  phx-value-type="full"
                  class="w-3.5 h-3.5 text-accent-purple"
                />
                <div>
                  <div class="text-ink-blue font-medium text-sm font-brand">
                    Full Workshop Report
                  </div>
                  <div class="text-ink-blue/50 text-xs font-brand">
                    All scores, participants, notes, and action items
                  </div>
                </div>
              </label>
              <label class={[
                "flex items-center gap-3 p-2.5 rounded-lg cursor-pointer transition-all border",
                if(@export_report_type == "team",
                  do: "bg-accent-purple/10 border-accent-purple",
                  else: "bg-surface-wall border-ink-blue/10 hover:border-ink-blue/20"
                )
              ]}>
                <input
                  type="radio"
                  name="export_report_type"
                  value="team"
                  checked={@export_report_type == "team"}
                  phx-click="select_export_report_type"
                  phx-value-type="team"
                  class="w-3.5 h-3.5 text-accent-purple"
                />
                <div>
                  <div class="text-ink-blue font-medium text-sm font-brand">Team Report</div>
                  <div class="text-ink-blue/50 text-xs font-brand">
                    Anonymized team results — no individual scores or names
                  </div>
                </div>
              </label>
            </div>

            <div class="grid grid-cols-2 gap-2">
              <button
                type="button"
                phx-click="export"
                phx-value-format="csv"
                class="btn-workshop btn-workshop-primary py-2.5"
              >
                Export CSV
              </button>
              <button
                type="button"
                phx-click="export"
                phx-value-format="pdf"
                class="btn-workshop btn-workshop-secondary py-2.5"
              >
                Export PDF
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
