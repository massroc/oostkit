defmodule WorkgroupPulseWeb.Analytics do
  @moduledoc """
  Helper module for analytics integration (PostHog).

  ## Setup

  Set these environment variables to enable PostHog:
  - `POSTHOG_API_KEY` - Your PostHog project API key (required)
  - `POSTHOG_HOST` - PostHog host URL (optional, defaults to https://us.i.posthog.com)

  ## Usage in Templates

  The PostHog script is automatically included in root.html.heex when configured.

  ## Usage in LiveView

  To track custom events from LiveView, push events to the client:

      # In your LiveView
      {:noreply, push_event(socket, "posthog:capture", %{
        event: "score_submitted",
        properties: %{question_index: 1, scale_type: "balance"}
      })}

  The JavaScript hook in app.js will forward these to PostHog.
  """

  @doc """
  Returns PostHog configuration for use in templates.
  """
  def config do
    Application.get_env(:workgroup_pulse, :posthog, [])
  end

  @doc """
  Returns true if PostHog is enabled.
  """
  def enabled? do
    config()[:enabled] == true
  end

  @doc """
  Returns the PostHog API key, or nil if not configured.
  """
  def api_key do
    config()[:api_key]
  end

  @doc """
  Returns the PostHog host URL.
  """
  def host do
    config()[:host] || "https://us.i.posthog.com"
  end
end
