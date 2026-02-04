defmodule Wrt.Repo do
  use Ecto.Repo,
    otp_app: :wrt,
    adapter: Ecto.Adapters.Postgres
end
