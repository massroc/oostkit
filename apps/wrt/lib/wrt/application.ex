defmodule Wrt.Application do
  @moduledoc """
  The Wrt Application.

  Starts the supervision tree including:
  - Ecto Repo
  - PubSub
  - Oban (background jobs)
  - Phoenix Endpoint
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WrtWeb.Telemetry,
      Wrt.Repo,
      {DNSCluster, query: Application.get_env(:wrt, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Wrt.PubSub},
      # Start Oban for background jobs
      {Oban, Application.fetch_env!(:wrt, Oban)},
      # Start the Finch HTTP client for Swoosh
      {Finch, name: Wrt.Finch},
      # Start Portal auth ETS cache
      OostkitShared.PortalAuthClient,
      # Start ETS storage for rate limiting
      {PlugAttack.Storage.Ets, name: WrtWeb.Plugs.RateLimiter.Storage, clean_period: 60_000},
      # Start the Endpoint (http/https)
      WrtWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Wrt.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WrtWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
