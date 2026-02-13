defmodule Portal.StatusPoller do
  @moduledoc """
  GenServer that polls app health endpoints and GitHub CI status every 5 minutes.
  Broadcasts results via PubSub so connected LiveViews can update in real time.
  """

  use GenServer

  require Logger

  @poll_interval :timer.minutes(5)
  @health_timeout 5_000
  @pubsub_topic "status_updates"

  @apps [
    %{name: "Portal", url: "https://oostkit.com", workflow: "portal.yml"},
    %{name: "Pulse", url: "https://pulse.oostkit.com", workflow: "workgroup_pulse.yml"},
    %{name: "WRT", url: "https://wrt.oostkit.com", workflow: "wrt.yml"}
  ]

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  def refresh do
    GenServer.cast(__MODULE__, :refresh)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Portal.PubSub, @pubsub_topic)
  end

  # Server callbacks

  @impl true
  def init(opts) do
    poll_interval = Keyword.get(opts, :poll_interval, @poll_interval)
    poll_on_init = Keyword.get(opts, :poll_on_init, true)

    state = %{
      health: %{},
      ci: %{},
      last_polled: nil,
      poll_interval: poll_interval
    }

    if poll_on_init, do: send(self(), :poll)

    {:ok, state}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, Map.take(state, [:health, :ci, :last_polled]), state}
  end

  @impl true
  def handle_cast(:refresh, state) do
    send(self(), :poll)
    {:noreply, state}
  end

  @impl true
  def handle_info(:poll, state) do
    health = poll_health_endpoints()
    ci = poll_ci_status()
    now = DateTime.utc_now()

    new_state = %{state | health: health, ci: ci, last_polled: now}

    Phoenix.PubSub.broadcast(
      Portal.PubSub,
      @pubsub_topic,
      {:status_update, Map.take(new_state, [:health, :ci, :last_polled])}
    )

    Process.send_after(self(), :poll, state.poll_interval)

    {:noreply, new_state}
  end

  # Health check polling

  defp poll_health_endpoints do
    @apps
    |> Task.async_stream(
      fn app ->
        {app.name, check_health(app.url)}
      end,
      timeout: @health_timeout + 1_000,
      on_timeout: :kill_task
    )
    |> Enum.reduce(%{}, fn
      {:ok, {name, result}}, acc -> Map.put(acc, name, result)
      {:exit, _reason}, acc -> acc
    end)
  end

  defp check_health(base_url) do
    url = "#{base_url}/health"
    start_time = System.monotonic_time(:millisecond)

    case Req.get(url,
           receive_timeout: @health_timeout,
           connect_options: [timeout: @health_timeout]
         ) do
      {:ok, %Req.Response{status: status, body: body}} ->
        response_time = System.monotonic_time(:millisecond) - start_time

        %{
          status: status,
          healthy: status == 200,
          response_time_ms: response_time,
          body: body,
          checked_at: DateTime.utc_now()
        }

      {:error, reason} ->
        %{
          status: nil,
          healthy: false,
          response_time_ms: nil,
          error: inspect(reason),
          checked_at: DateTime.utc_now()
        }
    end
  end

  # GitHub CI status polling

  defp poll_ci_status do
    repo = Application.get_env(:portal, :github_repo, "rossm/oostkit")
    token = Application.get_env(:portal, :github_token)

    @apps
    |> Task.async_stream(
      fn app ->
        {app.name, fetch_workflow_runs(repo, app.workflow, token)}
      end,
      timeout: 10_000,
      on_timeout: :kill_task
    )
    |> Enum.reduce(%{}, fn
      {:ok, {name, result}}, acc -> Map.put(acc, name, result)
      {:exit, _reason}, acc -> acc
    end)
  end

  defp fetch_workflow_runs(repo, workflow, token) do
    url = "https://api.github.com/repos/#{repo}/actions/workflows/#{workflow}/runs"

    headers =
      [{"accept", "application/vnd.github+json"}, {"user-agent", "Portal-StatusPoller"}]
      |> maybe_add_auth(token)

    case Req.get(url,
           headers: headers,
           params: %{branch: "main", per_page: 5},
           receive_timeout: @health_timeout
         ) do
      {:ok, %Req.Response{status: 200, body: %{"workflow_runs" => runs}}} ->
        runs
        |> Enum.take(5)
        |> Enum.map(fn run ->
          %{
            conclusion: run["conclusion"],
            status: run["status"],
            created_at: run["created_at"],
            html_url: run["html_url"],
            head_sha: String.slice(run["head_sha"] || "", 0..6)
          }
        end)

      {:ok, %Req.Response{status: status}} ->
        Logger.warning("GitHub API returned #{status} for #{workflow}")
        []

      {:error, reason} ->
        Logger.warning("GitHub API error for #{workflow}: #{inspect(reason)}")
        []
    end
  end

  defp maybe_add_auth(headers, nil), do: headers
  defp maybe_add_auth(headers, token), do: [{"authorization", "Bearer #{token}"} | headers]
end
