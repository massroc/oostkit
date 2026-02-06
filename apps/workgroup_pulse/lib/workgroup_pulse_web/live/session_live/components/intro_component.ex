defmodule WorkgroupPulseWeb.SessionLive.Components.IntroComponent do
  @moduledoc """
  Renders the introduction phase as a sheet on the Virtual Wall.
  Includes 4 intro steps: welcome, how it works, balance scale, and safe space.
  Pure functional component - all events bubble to parent LiveView.
  """
  use Phoenix.Component

  import WorkgroupPulseWeb.CoreComponents, only: [sheet: 1]

  attr :intro_step, :integer, required: true
  attr :participant, :map, required: true

  def render(assigns) do
    ~H"""
    <.sheet class="shadow-sheet p-6 max-w-2xl w-full">
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
      
    <!-- Navigation -->
      <div class="flex items-center justify-between mt-8 pt-4 border-t border-ink-blue/10">
        <div>
          <%= if @intro_step > 1 do %>
            <button
              phx-click="intro_prev"
              class="text-ink-blue/60 hover:text-ink-blue transition-colors font-brand text-sm"
            >
              ← Back
            </button>
          <% else %>
            <div></div>
          <% end %>
        </div>
        
    <!-- Step indicators -->
        <div class="flex items-center gap-1.5">
          <%= for step <- 1..4 do %>
            <div class={[
              "w-6 h-5 rounded-sm border transition-all",
              if(step == @intro_step,
                do: "border-accent-purple bg-surface-sheet shadow-sm",
                else: "border-ink-blue/10 bg-surface-sheet-secondary"
              )
            ]}>
              <%= if step == @intro_step do %>
                <div class="w-full h-full flex items-end justify-center pb-0.5">
                  <div class="w-1.5 h-1.5 rounded-full bg-accent-gold"></div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>

        <div>
          <%= if @intro_step < 4 do %>
            <div class="flex items-center gap-4">
              <%= if @intro_step == 1 do %>
                <button
                  phx-click="skip_intro"
                  class="text-ink-blue/50 hover:text-ink-blue/70 text-sm transition-colors font-brand"
                >
                  Skip intro
                </button>
              <% end %>

              <button
                phx-click="intro_next"
                class="btn-workshop btn-workshop-primary"
              >
                Next →
              </button>
            </div>
          <% else %>
            <div></div>
          <% end %>
        </div>
      </div>
    </.sheet>
    """
  end

  defp render_intro_welcome(assigns) do
    ~H"""
    <div class="text-center min-h-[340px]">
      <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-6">
        Welcome to the Workshop
      </h1>

      <div class="text-ink-blue/80 space-y-6 text-lg leading-relaxed">
        <p>
          This workshop helps your team have a meaningful conversation about what makes work engaging and productive.
        </p>

        <p>
          Based on forty years of research by Fred and Merrelyn Emery, the Six Criteria are the psychological factors that determine whether work is motivating or draining.
        </p>

        <blockquote class="italic text-ink-blue/70 border-l-4 border-traffic-green pl-4 text-left my-6">
          "If you don't get these criteria right, there will not be the human interest to see the job through."
          <span class="block text-sm mt-2 not-italic text-ink-blue/50">— Fred Emery</span>
        </blockquote>
      </div>
    </div>
    """
  end

  defp render_intro_how_it_works(assigns) do
    ~H"""
    <div class="text-center min-h-[340px]">
      <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-6">
        How This Workshop Works
      </h1>

      <div class="text-ink-blue/80 text-lg text-left leading-relaxed">
        <p class="mb-6">You'll work through 8 questions covering 6 criteria together as a team.</p>

        <p class="font-semibold text-ink-blue mb-3">For each question:</p>

        <ol class="list-decimal list-inside space-y-1.5 pl-4 text-ink-blue/70">
          <li>Everyone scores independently (your score stays hidden)</li>
          <li>Once everyone has submitted, all scores are revealed</li>
          <li>You discuss what you see — especially any differences</li>
          <li>When ready, you move to the next question</li>
        </ol>

        <p class="text-ink-blue/70 mt-6">
          The goal isn't to "fix" scores — it's to
          <span class="text-ink-blue font-semibold">surface and understand</span>
          different experiences within your team.
        </p>
      </div>
    </div>
    """
  end

  defp render_intro_balance_scale(assigns) do
    ~H"""
    <div class="text-center min-h-[340px]">
      <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-6">
        Understanding the Balance Scale
      </h1>

      <div class="text-ink-blue/80 text-lg text-left leading-relaxed">
        <p class="mb-4">
          The first four questions use a
          <span class="text-ink-blue font-semibold">balance scale</span>
          from -5 to +5:
        </p>

        <div class="bg-surface-wall rounded-lg p-6 my-4">
          <div class="flex justify-between items-center mb-4">
            <span class="text-accent-red font-semibold font-workshop text-xl">-5</span>
            <span class="text-traffic-green font-semibold text-2xl font-workshop">0</span>
            <span class="text-accent-red font-semibold font-workshop text-xl">+5</span>
          </div>

          <div class="flex justify-between items-center text-sm text-ink-blue/60">
            <span>Too little</span>
            <span>Just right</span>
            <span>Too much</span>
          </div>
        </div>

        <ul class="space-y-1.5 pl-4 text-ink-blue/70">
          <li>• These criteria need the right amount — not too much, not too little</li>
          <li>• <span class="text-traffic-green font-semibold">0 is optimal</span> (balanced)</li>
          <li>• Negative means too little, positive means too much</li>
        </ul>

        <p class="text-ink-blue/60 mt-6">
          Don't overthink — go with your gut feeling about your current experience.
        </p>
      </div>
    </div>
    """
  end

  defp render_intro_safe_space(assigns) do
    ~H"""
    <div class="text-center min-h-[340px]">
      <h1 class="font-workshop text-3xl font-bold text-ink-blue mb-6">
        Creating a Safe Space
      </h1>

      <div class="text-ink-blue/80 text-lg text-left leading-relaxed">
        <p class="mb-4">
          This workshop operates under the <span class="text-ink-blue font-semibold">Prime Directive</span>:
        </p>

        <blockquote class="italic text-ink-blue/70 border-l-4 border-accent-purple pl-4 my-4">
          "Regardless of what we discover, we understand and truly believe that everyone did the best job they could, given what they knew at the time, their skills and abilities, the resources available, and the situation at hand."
          <span class="block text-sm mt-2 not-italic text-ink-blue/50">— Norm Kerth</span>
        </blockquote>

        <p class="mb-4 text-ink-blue/70">
          Your scores reflect the <span class="text-ink-blue">system and environment</span>
          — not individual failings. Low scores aren't accusations; they're opportunities to improve how work is structured.
        </p>

        <ul class="space-y-1.5 pl-4 text-ink-blue/70">
          <li>
            • <span class="text-ink-blue">Be honest</span>
            — this only works if people share their real experience
          </li>
          <li>• There are no right or wrong scores</li>
          <li>• Differences are expected — they reveal different experiences</li>
          <li>• Your individual scores are visible only to this team</li>
        </ul>

        <div class="mt-8 text-center">
          <%= if @participant.is_facilitator do %>
            <button
              phx-click="continue_to_scoring"
              class="btn-workshop bg-traffic-green text-white text-xl px-12 py-4 shadow-lg hover:shadow-xl hover:-translate-y-0.5 transition-all"
            >
              Ready
            </button>
          <% else %>
            <p class="text-ink-blue/60 text-sm font-brand">
              Waiting for facilitator to start...
            </p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
