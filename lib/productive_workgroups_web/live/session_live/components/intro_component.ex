defmodule ProductiveWorkgroupsWeb.SessionLive.Components.IntroComponent do
  @moduledoc """
  Renders the introduction phase of a workshop session.
  Includes 4 intro steps: welcome, how it works, balance scale, and safe space.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  attr :intro_step, :integer, required: true
  attr :participant, :map, required: true

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen px-4">
      <div class="max-w-2xl w-full">
        <%= case @intro_step do %>
          <% 1 -> %>
            {render_intro_welcome(assigns)}
          <% 2 -> %>
            {render_intro_how_it_works(assigns)}
          <% 3 -> %>
            {render_intro_balance_scale(assigns)}
          <% 4 -> %>
            {render_intro_safe_space(assigns)}
          <% _ -> %>
            {render_intro_welcome(assigns)}
        <% end %>
        
        <div class="flex items-center justify-between mt-8">
          <div>
            <%= if @intro_step > 1 do %>
              <button
                phx-click="intro_prev"
                class="px-4 py-2 text-gray-400 hover:text-white transition-colors"
              >
                ← Back
              </button>
            <% else %>
              <div></div>
            <% end %>
          </div>
          
          <div class="flex items-center gap-2">
            <%= for step <- 1..4 do %>
              <div class={[
                "w-2 h-2 rounded-full",
                if(step == @intro_step, do: "bg-green-500", else: "bg-gray-600")
              ]} />
            <% end %>
          </div>
          
          <div>
            <%= if @intro_step < 4 do %>
              <div class="flex items-center gap-4">
                <%= if @intro_step == 1 do %>
                  <button
                    phx-click="skip_intro"
                    class="px-4 py-2 text-gray-500 hover:text-gray-300 text-sm transition-colors"
                  >
                    Skip intro
                  </button>
                <% end %>
                
                <button
                  phx-click="intro_next"
                  class="px-6 py-2 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors"
                >
                  Next →
                </button>
              </div>
            <% else %>
              <%= if @participant.is_facilitator do %>
                <button
                  phx-click="continue_to_scoring"
                  class="px-6 py-3 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors"
                >
                  Begin Scoring →
                </button>
              <% else %>
                <span class="text-gray-500 text-sm">Waiting for facilitator...</span>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_intro_welcome(assigns) do
    ~H"""
    <div class="text-center min-h-[340px]">
      <h1 class="text-3xl font-bold text-white mb-6">Welcome to the Six Criteria Workshop</h1>
      
      <div class="text-gray-300 space-y-8 text-lg leading-tight">
        <p>
          This workshop helps your team have a meaningful conversation about what makes work engaging and productive.
        </p>
        
        <p>
          Based on forty years of research by Fred and Merrelyn Emery, the Six Criteria are the psychological factors that determine whether work is motivating or draining.
        </p>
        
        <p class="italic text-gray-400 border-l-4 border-green-600 pl-4 text-left">
          "If you don't get these criteria right, there will not be the human interest to see the job through."
          <span class="block text-sm mt-1 not-italic">— Fred Emery</span>
        </p>
      </div>
    </div>
    """
  end

  defp render_intro_how_it_works(assigns) do
    ~H"""
    <div class="text-center min-h-[340px]">
      <h1 class="text-3xl font-bold text-white mb-6">How This Workshop Works</h1>
      
      <div class="text-gray-300 text-lg text-left leading-tight">
        <p class="mb-6">You'll work through 8 questions covering 6 criteria together as a team.</p>
        
        <p class="font-semibold text-white mb-2">For each question:</p>
        
        <ol class="list-decimal list-inside space-y-0.5 pl-4">
          <li>Everyone scores independently (your score stays hidden)</li>
          
          <li>Once everyone has submitted, all scores are revealed</li>
          
          <li>You discuss what you see — especially any differences</li>
          
          <li>When ready, you move to the next question</li>
        </ol>
        
        <p class="text-gray-400 mt-6">
          The goal isn't to "fix" scores — it's to
          <span class="text-white font-semibold">surface and understand</span>
          different experiences within your team.
        </p>
      </div>
    </div>
    """
  end

  defp render_intro_balance_scale(assigns) do
    ~H"""
    <div class="text-center min-h-[340px]">
      <h1 class="text-3xl font-bold text-white mb-6">Understanding the Balance Scale</h1>
      
      <div class="text-gray-300 text-lg text-left leading-tight">
        <p class="mb-4">
          The first four questions use a <span class="text-white font-semibold">balance scale</span>
          from -5 to +5:
        </p>
        
        <div class="bg-gray-800 rounded-lg p-6 my-4">
          <div class="flex justify-between items-center mb-4">
            <span class="text-red-400 font-semibold">-5</span>
            <span class="text-green-400 font-semibold text-xl">0</span>
            <span class="text-red-400 font-semibold">+5</span>
          </div>
          
          <div class="flex justify-between items-center text-sm text-gray-400">
            <span>Too little</span> <span>Just right</span> <span>Too much</span>
          </div>
        </div>
        
        <ul class="space-y-0.5 pl-4">
          <li>• These criteria need the right amount — not too much, not too little</li>
          
          <li>• <span class="text-green-400 font-semibold">0 is optimal</span> (balanced)</li>
          
          <li>• Negative means too little, positive means too much</li>
        </ul>
        
        <p class="text-gray-400 mt-6">
          Don't overthink — go with your gut feeling about your current experience.
        </p>
      </div>
    </div>
    """
  end

  defp render_intro_safe_space(assigns) do
    ~H"""
    <div class="text-center min-h-[340px]">
      <h1 class="text-3xl font-bold text-white mb-6">Creating a Safe Space</h1>
      
      <div class="text-gray-300 text-lg text-left leading-tight">
        <p class="mb-4">
          This workshop operates under the <span class="text-white font-semibold">Prime Directive</span>:
        </p>
        
        <blockquote class="italic text-gray-400 border-l-4 border-purple-600 pl-4 my-4">
          "Regardless of what we discover, we understand and truly believe that everyone did the best job they could, given what they knew at the time, their skills and abilities, the resources available, and the situation at hand."
          <span class="block text-sm mt-1 not-italic">— Norm Kerth</span>
        </blockquote>
        
        <p class="mb-4">
          Your scores reflect the <span class="text-white">system and environment</span>
          — not individual failings. Low scores aren't accusations; they're opportunities to improve how work is structured.
        </p>
        
        <ul class="space-y-0.5 pl-4">
          <li>
            • <span class="text-white">Be honest</span>
            — this only works if people share their real experience
          </li>
          
          <li>• There are no right or wrong scores</li>
          
          <li>• Differences are expected — they reveal different experiences</li>
          
          <li>• Your individual scores are visible only to this team</li>
        </ul>
        
        <div class="bg-gray-800 rounded-lg p-4 mt-6 text-center">
          <p class="text-white font-semibold">Ready?</p>
          
          <p class="text-gray-400 text-sm mt-1">
            When everyone is ready, the facilitator will begin scoring.
          </p>
        </div>
      </div>
    </div>
    """
  end
end
