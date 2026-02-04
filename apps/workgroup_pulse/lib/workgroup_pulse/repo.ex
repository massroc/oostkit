defmodule WorkgroupPulse.Repo do
  use Ecto.Repo,
    otp_app: :workgroup_pulse,
    adapter: Ecto.Adapters.Postgres
end
