ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Wrt.Repo, :manual)

# Start the ETS table for rate limiting if it doesn't exist
try do
  :ets.new(WrtWeb.Plugs.RateLimiter.Storage, [:named_table, :set, :public])
rescue
  ArgumentError -> :ok
end
