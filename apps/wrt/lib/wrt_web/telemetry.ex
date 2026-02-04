defmodule WrtWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("wrt.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("wrt.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("wrt.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("wrt.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("wrt.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),

      # Oban Metrics
      counter("oban.job.start.count",
        tags: [:queue, :worker],
        description: "Count of jobs started"
      ),
      summary("oban.job.stop.duration",
        tags: [:queue, :worker],
        unit: {:native, :millisecond},
        description: "Duration of job execution"
      ),
      counter("oban.job.exception.count",
        tags: [:queue, :worker],
        description: "Count of job exceptions"
      ),

      # WRT Business Metrics
      counter("wrt.auth.login.count",
        tags: [:result],
        description: "Count of login attempts"
      ),
      counter("wrt.auth.magic_link.count",
        tags: [:action],
        description: "Magic link operations"
      ),
      counter("wrt.nomination.submit.count",
        tags: [:tenant],
        description: "Nomination submissions"
      ),
      counter("wrt.email.send.count",
        tags: [:type, :result],
        description: "Emails sent"
      ),
      counter("wrt.rate_limit.blocked.count",
        tags: [:path],
        description: "Rate limited requests"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      {__MODULE__, :measure_oban_queue_lengths, []}
    ]
  end

  @doc """
  Measures Oban queue lengths for monitoring.
  """
  def measure_oban_queue_lengths do
    if Process.whereis(Oban) do
      queues = [:default, :emails, :rounds, :maintenance]

      Enum.each(queues, fn queue ->
        count =
          case Oban.check_queue(queue: queue) do
            %{running: running} when is_list(running) -> length(running)
            _ -> 0
          end

        :telemetry.execute(
          [:wrt, :oban, :queue_length],
          %{count: count},
          %{queue: queue}
        )
      end)
    end
  rescue
    _ -> :ok
  end
end
