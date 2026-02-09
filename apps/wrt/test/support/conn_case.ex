defmodule WrtWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use WrtWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint WrtWeb.Endpoint

      use WrtWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import WrtWeb.ConnCase
      import Wrt.Factory
      import Wrt.DataCase, only: [create_test_tenant: 0, insert_in_tenant: 2, insert_in_tenant: 3]
    end
  end

  setup tags do
    Wrt.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Logs in a super admin by setting the session.
  """
  def log_in_super_admin(conn, super_admin) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:super_admin_id, super_admin.id)
  end

  @doc """
  Logs in an org admin by setting the session.
  """
  def log_in_org_admin(conn, org_admin) do
    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:org_admin_id, org_admin.id)
  end

  @doc """
  Creates an approved org with its tenant schema and returns
  {org, tenant} for use in org-scoped controller tests.
  """
  def create_org_with_tenant do
    org = Wrt.Repo.insert!(Wrt.Factory.build(:approved_organisation))
    tenant = "tenant_#{org.id}"
    Wrt.DataCase.create_tenant_tables(tenant)
    {org, tenant}
  end
end
