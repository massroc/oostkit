defmodule Portal.Application do
  @moduledoc """
  The Portal Application.

  Starts the supervision tree including:
  - Ecto Repo
  - PubSub
  - Phoenix Endpoint
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PortalWeb.Telemetry,
      Portal.Repo,
      {DNSCluster, query: Application.get_env(:portal, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Portal.PubSub},
      # Start the Finch HTTP client for Swoosh
      {Finch, name: Portal.Finch},
      # Start the Endpoint (http/https)
      PortalWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Portal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PortalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
