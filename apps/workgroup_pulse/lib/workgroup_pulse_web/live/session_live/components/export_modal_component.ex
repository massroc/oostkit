defmodule WorkgroupPulseWeb.SessionLive.Components.ExportModalComponent do
  @moduledoc """
  Renders the export button and modal for downloading workshop results.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  attr :show_export_modal, :boolean, required: true
  attr :export_content, :string, required: true
  attr :action_count, :integer, required: true

  def render(assigns) do
    ~H"""
    <div>
      <%!-- Export Button --%>
      <div id="export-container" phx-hook="FileDownload">
        <button
          type="button"
          phx-click="toggle_export_modal"
          class="w-full btn-workshop btn-workshop-primary py-2.5 flex items-center justify-center gap-2"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
            />
          </svg>
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
              <h3 class="font-workshop text-xl font-bold text-ink-blue">Export Data</h3>
              <button
                type="button"
                phx-click="close_export_modal"
                class="text-ink-blue/30 hover:text-ink-blue/60 transition-colors"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <p class="text-ink-blue/60 text-xs font-brand mb-4">
              Select what to include in the export.
            </p>

            <div class="space-y-2 mb-4">
              <label class={[
                "flex items-center gap-3 p-2.5 rounded-lg cursor-pointer transition-all border",
                if(@export_content == "all",
                  do: "bg-accent-purple/10 border-accent-purple",
                  else: "bg-surface-wall border-ink-blue/10 hover:border-ink-blue/20"
                )
              ]}>
                <input
                  type="radio"
                  name="export_content"
                  value="all"
                  checked={@export_content == "all"}
                  phx-click="select_export_content"
                  phx-value-content="all"
                  class="w-3.5 h-3.5 text-accent-purple"
                />
                <div>
                  <div class="text-ink-blue font-medium text-sm font-brand">Everything</div>
                  <div class="text-ink-blue/50 text-xs font-brand">
                    Results, notes, and action items
                  </div>
                </div>
              </label>
              <label class={[
                "flex items-center gap-3 p-2.5 rounded-lg cursor-pointer transition-all border",
                if(@export_content == "results",
                  do: "bg-accent-purple/10 border-accent-purple",
                  else: "bg-surface-wall border-ink-blue/10 hover:border-ink-blue/20"
                )
              ]}>
                <input
                  type="radio"
                  name="export_content"
                  value="results"
                  checked={@export_content == "results"}
                  phx-click="select_export_content"
                  phx-value-content="results"
                  class="w-3.5 h-3.5 text-accent-purple"
                />
                <div>
                  <div class="text-ink-blue font-medium text-sm font-brand">Results Only</div>
                  <div class="text-ink-blue/50 text-xs font-brand">
                    Scores, participants, and notes
                  </div>
                </div>
              </label>
              <label class={[
                "flex items-center gap-3 p-2.5 rounded-lg transition-all border",
                cond do
                  @action_count == 0 ->
                    "bg-surface-wall border-ink-blue/10 cursor-not-allowed opacity-40"

                  @export_content == "actions" ->
                    "bg-accent-purple/10 border-accent-purple cursor-pointer"

                  true ->
                    "bg-surface-wall border-ink-blue/10 hover:border-ink-blue/20 cursor-pointer"
                end
              ]}>
                <input
                  type="radio"
                  name="export_content"
                  value="actions"
                  checked={@export_content == "actions"}
                  disabled={@action_count == 0}
                  phx-click="select_export_content"
                  phx-value-content="actions"
                  class="w-3.5 h-3.5 text-accent-purple"
                />
                <div>
                  <div class={[
                    "font-medium text-sm font-brand",
                    if(@action_count == 0, do: "text-ink-blue/40", else: "text-ink-blue")
                  ]}>
                    Actions Only
                  </div>
                  <div class="text-ink-blue/50 text-xs font-brand">
                    <%= if @action_count == 0 do %>
                      No action items recorded
                    <% else %>
                      Action items with owners
                    <% end %>
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
                phx-value-format="json"
                class="btn-workshop btn-workshop-secondary py-2.5"
              >
                Export JSON
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
