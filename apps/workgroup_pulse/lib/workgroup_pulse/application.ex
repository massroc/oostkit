defmodule WorkgroupPulse.Application do
  @moduledoc """
  The WorkgroupPulse Application.

  Starts the supervision tree including:
  - Ecto Repo
  - PubSub (for real-time features)
  - Presence (for participant tracking)
  - Phoenix Endpoint
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WorkgroupPulseWeb.Telemetry,
      WorkgroupPulse.Repo,
      {DNSCluster,
       query: Application.get_env(:workgroup_pulse, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WorkgroupPulse.PubSub},
      # Presence for tracking participants in sessions
      WorkgroupPulseWeb.Presence,
      # Start the Finch HTTP client for Swoosh
      {Finch, name: WorkgroupPulse.Finch},
      # Start the Endpoint (http/https)
      WorkgroupPulseWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: WorkgroupPulse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WorkgroupPulseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
