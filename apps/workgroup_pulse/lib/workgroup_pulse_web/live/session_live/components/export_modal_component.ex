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
      <!-- Export Button -->
      <div class="bg-gray-800 rounded-lg p-4 mb-6" id="export-container" phx-hook="FileDownload">
        <button
          type="button"
          phx-click="toggle_export_modal"
          class="w-full px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors flex items-center justify-center gap-2"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
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
      <!-- Export Modal -->
      <%= if @show_export_modal do %>
        <div
          class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
          phx-click-away="close_export_modal"
        >
          <div class="bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-white">Export Workshop Data</h3>

              <button
                type="button"
                phx-click="close_export_modal"
                class="text-gray-400 hover:text-white"
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

            <p class="text-gray-400 text-sm mb-6">Select what to include in the export.</p>

            <div class="space-y-3 mb-6">
              <label class={[
                "flex items-center gap-3 p-3 rounded-lg cursor-pointer transition-colors",
                if(@export_content == "all",
                  do: "bg-blue-600/20 border border-blue-500",
                  else: "bg-gray-700 border border-gray-600 hover:bg-gray-600"
                )
              ]}>
                <input
                  type="radio"
                  name="export_content"
                  value="all"
                  checked={@export_content == "all"}
                  phx-click="select_export_content"
                  phx-value-content="all"
                  class="w-4 h-4 text-blue-600"
                />
                <div>
                  <div class="text-white font-medium">Everything</div>

                  <div class="text-gray-400 text-sm">Results, notes, and action items</div>
                </div>
              </label>
              <label class={[
                "flex items-center gap-3 p-3 rounded-lg cursor-pointer transition-colors",
                if(@export_content == "results",
                  do: "bg-blue-600/20 border border-blue-500",
                  else: "bg-gray-700 border border-gray-600 hover:bg-gray-600"
                )
              ]}>
                <input
                  type="radio"
                  name="export_content"
                  value="results"
                  checked={@export_content == "results"}
                  phx-click="select_export_content"
                  phx-value-content="results"
                  class="w-4 h-4 text-blue-600"
                />
                <div>
                  <div class="text-white font-medium">Results Only</div>

                  <div class="text-gray-400 text-sm">Scores, participants, and notes</div>
                </div>
              </label>
              <label class={[
                "flex items-center gap-3 p-3 rounded-lg transition-colors",
                cond do
                  @action_count == 0 ->
                    "bg-gray-800 border border-gray-700 cursor-not-allowed opacity-50"

                  @export_content == "actions" ->
                    "bg-blue-600/20 border border-blue-500 cursor-pointer"

                  true ->
                    "bg-gray-700 border border-gray-600 hover:bg-gray-600 cursor-pointer"
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
                  class="w-4 h-4 text-blue-600"
                />
                <div>
                  <div class={
                    if @action_count == 0,
                      do: "text-gray-500 font-medium",
                      else: "text-white font-medium"
                  }>
                    Actions Only
                  </div>

                  <div class="text-gray-400 text-sm">
                    <%= if @action_count == 0 do %>
                      No action items recorded
                    <% else %>
                      Action items with owners
                    <% end %>
                  </div>
                </div>
              </label>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <button
                type="button"
                phx-click="export"
                phx-value-format="csv"
                class="px-4 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium"
              >
                Export CSV
              </button>
              <button
                type="button"
                phx-click="export"
                phx-value-format="json"
                class="px-4 py-3 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition-colors font-medium"
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
