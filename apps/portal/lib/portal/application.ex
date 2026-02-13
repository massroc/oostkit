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
    children =
      [
        PortalWeb.Telemetry,
        Portal.Repo,
        {DNSCluster, query: Application.get_env(:portal, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Portal.PubSub},
        # Start the Finch HTTP client for Swoosh
        {Finch, name: Portal.Finch},
        # Start the ETS storage for rate limiting
        {PlugAttack.Storage.Ets,
         name: PortalWeb.Plugs.RateLimiter.Storage, clean_period: 60_000},
        # Start the Endpoint (http/https)
        PortalWeb.Endpoint
      ] ++ maybe_status_poller()

    opts = [strategy: :one_for_one, name: Portal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PortalWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp maybe_status_poller do
    if Application.get_env(:portal, :start_status_poller, true) do
      [Portal.StatusPoller]
    else
      []
    end
  end
end
