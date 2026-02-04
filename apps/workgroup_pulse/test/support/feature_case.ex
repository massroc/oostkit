defmodule WorkgroupPulseWeb.FeatureCase do
  @moduledoc """
  This module defines the test case to be used by browser-based feature tests.

  Uses Wallaby for browser automation.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      alias WorkgroupPulse.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias WorkgroupPulseWeb.Router.Helpers, as: Routes

      @endpoint WorkgroupPulseWeb.Endpoint
    end
  end

  setup tags do
    pid =
      Ecto.Adapters.SQL.Sandbox.start_owner!(WorkgroupPulse.Repo, shared: not tags[:async])

    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(WorkgroupPulse.Repo, pid)
    {:ok, session} = Wallaby.start_session(metadata: metadata)

    {:ok, session: session}
  end
end
