defmodule ProductiveWorkgroupsWeb.SessionLive.Components.ScoringComponent do
  @moduledoc """
  Renders the scoring phase of a workshop session.
  Includes turn-based scoring input, score grid, and discussion results.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  alias ProductiveWorkgroupsWeb.SessionLive.ScoreResultsComponent

  import ProductiveWorkgroupsWeb.SessionLive.ScoreHelpers

  attr :session, :map, required: true
  attr :participant, :map, required: true
  attr :participants, :list, required: true
  attr :current_question, :map, required: true
  attr :all_scores, :list, required: true
  attr :selected_value, :any, required: true
  attr :my_score, :any, required: true
  attr :has_submitted, :boolean, required: true
  attr :is_my_turn, :boolean, required: true
  attr :current_turn_participant_id, :any, required: true
  attr :current_turn_has_score, :boolean, required: true
  attr :in_catch_up_phase, :boolean, required: true
  attr :my_turn_locked, :boolean, required: true
  attr :scores_revealed, :boolean, required: true
  attr :score_count, :integer, required: true
  attr :active_participant_count, :integer, required: true
  attr :show_mid_transition, :boolean, required: true
  attr :show_facilitator_tips, :boolean, required: true
  attr :question_notes, :list, required: true
  attr :show_notes, :boolean, required: true
  attr :note_input, :string, required: true

  def render(assigns) do
    ~H"""
    <%= if @show_mid_transition do %>
      {render_mid_transition(assigns)}
    <% else %>
      <div class="flex flex-col items-center min-h-screen px-4 py-8">
        <div class="max-w-2xl w-full">
          <!-- Progress indicator -->
          <div class="mb-6">
            <div class="flex justify-between items-center text-sm text-gray-400 mb-2">
              <span>Question {@session.current_question_index + 1} of 8</span>
              <span>{@score_count}/{@active_participant_count} submitted</span>
            </div>
            
            <div class="w-full bg-gray-700 rounded-full h-2">
              <div
                class="bg-green-500 h-2 rounded-full transition-all duration-300"
                style={"width: #{(@session.current_question_index + 1) / 8 * 100}%"}
              />
            </div>
          </div>
          <!-- Question card -->
          <div class="bg-gray-800 rounded-lg p-6 mb-6">
            <div class="text-sm text-green-400 mb-2">{@current_question.criterion_name}</div>
            
            <h1 class="text-2xl font-bold text-white mb-4">{@current_question.title}</h1>
            
            <p class="text-gray-300 whitespace-pre-line">
              {format_description(@current_question.explanation)}
            </p>
            
            <%= if length(@current_question.discussion_prompts) > 0 do %>
              <%= if @show_facilitator_tips do %>
                <!-- Expanded tips section -->
                <div class="mt-4 pt-4 border-t border-gray-700">
                  <div class="flex items-center justify-between mb-3">
                    <h3 class="text-sm font-semibold text-purple-400">Facilitator Tips</h3>
                    
                    <button
                      type="button"
                      phx-click="toggle_facilitator_tips"
                      class="text-sm text-gray-400 hover:text-white transition-colors"
                    >
                      Hide tips
                    </button>
                  </div>
                  
                  <ul class="space-y-2">
                    <%= for prompt <- @current_question.discussion_prompts do %>
                      <li class="flex gap-2 text-gray-300 text-sm">
                        <span class="text-purple-400">•</span> <span>{prompt}</span>
                      </li>
                    <% end %>
                  </ul>
                </div>
              <% else %>
                <!-- Collapsed state - show More tips button -->
                <button
                  type="button"
                  phx-click="toggle_facilitator_tips"
                  class="mt-4 text-sm text-purple-400 hover:text-purple-300 transition-colors flex items-center gap-1"
                >
                  <span>More tips</span> <span class="text-xs">+</span>
                </button>
              <% end %>
            <% end %>
          </div>
          <!-- Score grid showing all participants (butcher paper model) - only during scoring, not after reveal -->
          <%= if length(@all_scores) > 0 and not @scores_revealed do %>
            <div class="bg-gray-800 rounded-lg p-4 mb-4">
              <div class="flex flex-wrap gap-2 justify-center">
                <%= for s <- @all_scores do %>
                  <div class={[
                    "rounded p-2 text-center min-w-[60px] transition-all",
                    case s.state do
                      :scored ->
                        case s.color do
                          :green -> "bg-green-900/50 border border-green-700"
                          :amber -> "bg-yellow-900/50 border border-yellow-700"
                          :red -> "bg-red-900/50 border border-red-700"
                          _ -> "bg-gray-700 border border-gray-600"
                        end

                      :current ->
                        "bg-blue-900/30 border-2 border-blue-500 animate-pulse"

                      :skipped ->
                        "bg-gray-800 border border-gray-600"

                      :pending ->
                        "bg-gray-800/50 border border-gray-700"

                      _ ->
                        "bg-gray-700 border border-gray-600"
                    end
                  ]}>
                    <div class={[
                      "text-lg font-bold",
                      case s.state do
                        :scored ->
                          case s.color do
                            :green -> "text-green-400"
                            :amber -> "text-yellow-400"
                            :red -> "text-red-400"
                            _ -> "text-gray-400"
                          end

                        :current ->
                          "text-blue-400"

                        :skipped ->
                          "text-gray-500"

                        :pending ->
                          "text-gray-600"

                        _ ->
                          "text-gray-400"
                      end
                    ]}>
                      <%= case s.state do %>
                        <% :scored -> %>
                          <%= if @current_question.scale_type == "balance" and s.value > 0 do %>
                            +{s.value}
                          <% else %>
                            {s.value}
                          <% end %>
                        <% :current -> %>
                          ...
                        <% :skipped -> %>
                          ?
                        <% :pending -> %>
                          —
                        <% _ -> %>
                          —
                      <% end %>
                    </div>
                    
                    <div
                      class={[
                        "text-xs truncate",
                        if(s.state == :scored, do: "text-gray-400", else: "text-gray-500")
                      ]}
                      title={s.participant_name}
                    >
                      {s.participant_name}
                    </div>
                  </div>
                <% end %>
              </div>
              <!-- Discussion prompt when all scores are in -->
              <%= if @scores_revealed do %>
                <div class="mt-4 pt-4 border-t border-gray-700 text-center">
                  <p class="text-gray-300">
                    All scores are in. <span class="text-white font-semibold">Discuss as a team</span>
                    — look for variance across the group.
                  </p>
                </div>
              <% end %>
            </div>
          <% end %>
          
          <%= if @scores_revealed do %>
            <.live_component
              module={ScoreResultsComponent}
              id="score-results"
              all_scores={@all_scores}
              current_question={@current_question}
              show_notes={@show_notes}
              question_notes={@question_notes}
              note_input={@note_input}
              participant={@participant}
              session={@session}
            />
          <% else %>
            {render_score_input(assigns)}
            <!-- Facilitator navigation bar during scoring entry -->
            <%= if @participant.is_facilitator do %>
              <div class="bg-gray-800 rounded-lg p-6">
                <div class="flex gap-3">
                  <button
                    phx-click="go_back"
                    class="px-6 py-3 bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-white font-medium rounded-lg transition-colors flex items-center gap-2"
                  >
                    <span>←</span> <span>Back</span>
                  </button>
                  <button
                    disabled
                    class="flex-1 px-6 py-3 bg-gray-600 text-gray-400 font-semibold rounded-lg cursor-not-allowed"
                  >
                    <%= if @session.current_question_index + 1 >= 8 do %>
                      Continue to Summary →
                    <% else %>
                      Next Question →
                    <% end %>
                  </button>
                </div>
                
                <p class="text-center text-gray-500 text-sm mt-2">
                  Waiting for all scores to be submitted...
                </p>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp render_mid_transition(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen px-4">
      <div class="max-w-2xl w-full text-center">
        <div class="bg-gray-800 rounded-lg p-8">
          <div class="text-6xl mb-4">🔄</div>
          
          <h1 class="text-3xl font-bold text-white mb-6">New Scoring Scale Ahead</h1>
          
          <div class="text-gray-300 space-y-4 text-lg text-left">
            <p class="text-center">Great progress! You've completed the first four questions.</p>
            
            <div class="bg-gray-700 rounded-lg p-6 my-6">
              <p class="text-white font-semibold mb-3">
                The next four questions use a different scale:
              </p>
              
              <div class="flex justify-between items-center mb-4">
                <span class="text-gray-400">0</span>
                <span class="text-green-400 font-semibold text-xl">→</span>
                <span class="text-green-400 font-semibold">10</span>
              </div>
              
              <ul class="space-y-2 text-gray-300">
                <li>
                  • For these, <span class="text-green-400 font-semibold">more is always better</span>
                </li>
                
                <li>• <span class="text-green-400 font-semibold">10 is optimal</span></li>
              </ul>
            </div>
            
            <p class="text-gray-400 text-center">
              These measure aspects of work where you can never have too much.
            </p>
          </div>
          
          <button
            phx-click="continue_past_transition"
            class="mt-8 px-8 py-3 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors text-lg"
          >
            Continue to Question 5 →
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp render_score_input(assigns) do
    # Find current turn participant name for display
    current_turn_name =
      if assigns.current_turn_participant_id do
        Enum.find_value(assigns.participants, "Unknown", fn p ->
          if p.id == assigns.current_turn_participant_id, do: p.name
        end)
      else
        nil
      end

    assigns = assign(assigns, :current_turn_name, current_turn_name)

    ~H"""
    <div class="bg-gray-800 rounded-lg p-6 mb-6">
      <%= if @participant.is_observer do %>
        <div class="text-center">
          <div class="text-purple-400 text-lg font-semibold mb-2">Observer Mode</div>
          
          <p class="text-gray-400">You are observing this session.</p>
          
          <%= if @current_turn_name do %>
            <p class="text-gray-500 mt-2">
              <span class="text-white">{@current_turn_name}</span> is scoring
            </p>
          <% end %>
        </div>
      <% else %>
        <%= if @is_my_turn and not @my_turn_locked do %>
          <!-- It's this participant's turn -->
          <div class="text-center mb-4">
            <div class="text-green-400 text-lg font-semibold">Your turn to score</div>
            
            <%= if @in_catch_up_phase do %>
              <p class="text-gray-400 text-sm mt-1">Catch-up phase - add your score now</p>
            <% end %>
          </div>
          
          <%= if @current_question.scale_type == "balance" do %>
            {render_balance_scale(assigns)}
          <% else %>
            {render_maximal_scale(assigns)}
          <% end %>
          
          <div class="flex gap-3 mt-6">
            <button
              phx-click="submit_score"
              disabled={@selected_value == nil}
              class={[
                "flex-1 px-6 py-3 font-semibold rounded-lg transition-colors",
                if(@selected_value != nil and not @has_submitted,
                  do: "bg-blue-600 hover:bg-blue-700 text-white",
                  else: "bg-gray-600 text-gray-400 cursor-not-allowed"
                )
              ]}
            >
              <%= if @has_submitted do %>
                Score Placed
              <% else %>
                Place Score
              <% end %>
            </button>
            <button
              phx-click="complete_turn"
              disabled={not @has_submitted}
              class={[
                "flex-1 px-6 py-3 font-semibold rounded-lg transition-colors",
                if(@has_submitted,
                  do: "bg-green-600 hover:bg-green-700 text-white",
                  else: "bg-gray-600 text-gray-400 cursor-not-allowed"
                )
              ]}
            >
              Done →
            </button>
          </div>
          
          <%= if @has_submitted do %>
            <p class="text-center text-gray-400 text-sm mt-2">
              Discuss this score, then click "Done" when ready
            </p>
          <% end %>
        <% else %>
          <!-- Not this participant's turn, or they've completed their turn -->
          <div class="text-center">
            <%= if @current_turn_name do %>
              <p class="text-gray-400">
                <%= if @current_turn_has_score do %>
                  Discuss <span class="text-white">{@current_turn_name}</span>'s score
                <% else %>
                  Waiting for <span class="text-white">{@current_turn_name}</span> to score
                <% end %>
              </p>
              <!-- Skip button - facilitator only, only when current turn hasn't placed a score -->
              <%= if @participant.is_facilitator and not @current_turn_has_score do %>
                <div class="mt-4">
                  <button
                    phx-click="skip_turn"
                    class="text-sm text-gray-500 hover:text-gray-300 transition-colors"
                  >
                    Skip {String.split(@current_turn_name) |> List.first()}'s turn
                  </button>
                </div>
              <% end %>
            <% else %>
              <!-- No current turn - all done or between turns -->
              <p class="text-gray-400">Waiting for next turn...</p>
            <% end %>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp render_balance_scale(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex justify-between text-sm text-gray-400">
        <span>Too little</span> <span>Just right</span> <span>Too much</span>
      </div>
      
      <div class="flex gap-1">
        <%= for v <- -5..5 do %>
          <button
            type="button"
            phx-click="select_score"
            phx-value-score={v}
            class={[
              "flex-1 min-w-0 py-3 rounded-lg font-semibold text-sm transition-all cursor-pointer",
              cond do
                @selected_value == v -> "bg-green-500 text-white"
                v == 0 -> "bg-gray-600 text-white hover:bg-gray-500"
                true -> "bg-gray-700 text-gray-300 hover:bg-gray-600"
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
      
      <div class="flex justify-between text-xs text-gray-500">
        <span>-5</span> <span class="text-green-400">0 = optimal</span> <span>+5</span>
      </div>
    </div>
    """
  end

  defp render_maximal_scale(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex justify-between text-sm text-gray-400"><span>Low</span> <span>High</span></div>
      
      <div class="flex gap-1">
        <%= for v <- 0..10 do %>
          <button
            type="button"
            phx-click="select_score"
            phx-value-score={v}
            class={[
              "flex-1 min-w-0 py-3 rounded-lg font-semibold text-sm transition-all cursor-pointer",
              cond do
                @selected_value == v -> "bg-green-500 text-white"
                v >= 7 -> "bg-gray-600 text-white hover:bg-gray-500"
                true -> "bg-gray-700 text-gray-300 hover:bg-gray-600"
              end
            ]}
          >
            {v}
          </button>
        <% end %>
      </div>
      
      <div class="flex justify-between text-xs text-gray-500">
        <span>0</span> <span class="text-green-400">10 = best</span>
      </div>
    </div>
    """
  end
end
