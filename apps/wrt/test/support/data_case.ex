defmodule Wrt.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Wrt.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox
  alias Wrt.Factory
  alias Wrt.Repo

  using do
    quote do
      alias Wrt.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Wrt.DataCase
      import Wrt.Factory
    end
  end

  setup tags do
    Wrt.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Creates a test tenant schema.

  The schema will be cleaned up automatically by the sandbox.
  Returns the tenant schema name.
  """
  def create_test_tenant do
    # Use a unique ID for each test to avoid conflicts
    org_id = System.unique_integer([:positive])
    tenant = "tenant_#{org_id}"

    # Create the schema and tables directly with SQL
    create_tenant_tables(tenant)

    tenant
  end

  @doc """
  Creates all tenant tables directly with SQL.
  This avoids module redefinition issues from running migrations.
  """
  def create_tenant_tables(tenant) do
    SQL.query!(Repo, "CREATE SCHEMA IF NOT EXISTS #{tenant}", [])

    # Create campaigns table
    SQL.query!(
      Repo,
      """
        CREATE TABLE #{tenant}.campaigns (
          id BIGSERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          description TEXT,
          status VARCHAR(255) NOT NULL DEFAULT 'draft',
          default_round_duration_days INTEGER DEFAULT 7,
          target_participant_count INTEGER,
          started_at TIMESTAMP(0) WITHOUT TIME ZONE,
          completed_at TIMESTAMP(0) WITHOUT TIME ZONE,
          inserted_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
          updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
        )
      """,
      []
    )

    # Create people table
    SQL.query!(
      Repo,
      """
        CREATE TABLE #{tenant}.people (
          id BIGSERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) NOT NULL,
          source VARCHAR(255) NOT NULL DEFAULT 'nominated',
          inserted_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
          updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
        )
      """,
      []
    )

    SQL.query!(
      Repo,
      "CREATE UNIQUE INDEX ON #{tenant}.people (LOWER(email))",
      []
    )

    # Create rounds table
    SQL.query!(
      Repo,
      """
        CREATE TABLE #{tenant}.rounds (
          id BIGSERIAL PRIMARY KEY,
          campaign_id BIGINT NOT NULL REFERENCES #{tenant}.campaigns(id) ON DELETE CASCADE,
          round_number INTEGER NOT NULL,
          status VARCHAR(255) NOT NULL DEFAULT 'pending',
          deadline TIMESTAMP(0) WITHOUT TIME ZONE,
          reminder_enabled BOOLEAN DEFAULT false,
          reminder_days INTEGER DEFAULT 2,
          started_at TIMESTAMP(0) WITHOUT TIME ZONE,
          closed_at TIMESTAMP(0) WITHOUT TIME ZONE,
          inserted_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
          updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
          UNIQUE (campaign_id, round_number)
        )
      """,
      []
    )

    # Create contacts table
    SQL.query!(
      Repo,
      """
        CREATE TABLE #{tenant}.contacts (
          id BIGSERIAL PRIMARY KEY,
          person_id BIGINT NOT NULL REFERENCES #{tenant}.people(id) ON DELETE CASCADE,
          round_id BIGINT NOT NULL REFERENCES #{tenant}.rounds(id) ON DELETE CASCADE,
          email_status VARCHAR(255) NOT NULL DEFAULT 'pending',
          invited_at TIMESTAMP(0) WITHOUT TIME ZONE,
          delivered_at TIMESTAMP(0) WITHOUT TIME ZONE,
          opened_at TIMESTAMP(0) WITHOUT TIME ZONE,
          clicked_at TIMESTAMP(0) WITHOUT TIME ZONE,
          responded_at TIMESTAMP(0) WITHOUT TIME ZONE,
          inserted_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
          updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
          UNIQUE (person_id, round_id)
        )
      """,
      []
    )

    # Create nominations table
    SQL.query!(
      Repo,
      """
        CREATE TABLE #{tenant}.nominations (
          id BIGSERIAL PRIMARY KEY,
          round_id BIGINT NOT NULL REFERENCES #{tenant}.rounds(id) ON DELETE CASCADE,
          nominator_id BIGINT NOT NULL REFERENCES #{tenant}.people(id) ON DELETE CASCADE,
          nominee_id BIGINT NOT NULL REFERENCES #{tenant}.people(id) ON DELETE CASCADE,
          inserted_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
          updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
          UNIQUE (round_id, nominator_id, nominee_id)
        )
      """,
      []
    )

    # Create magic_links table
    SQL.query!(
      Repo,
      """
        CREATE TABLE #{tenant}.magic_links (
          id BIGSERIAL PRIMARY KEY,
          person_id BIGINT NOT NULL REFERENCES #{tenant}.people(id) ON DELETE CASCADE,
          round_id BIGINT NOT NULL REFERENCES #{tenant}.rounds(id) ON DELETE CASCADE,
          token VARCHAR(255) NOT NULL,
          code VARCHAR(255),
          code_expires_at TIMESTAMP(0) WITHOUT TIME ZONE,
          expires_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
          used_at TIMESTAMP(0) WITHOUT TIME ZONE,
          inserted_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
          updated_at TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL
        )
      """,
      []
    )

    SQL.query!(Repo, "CREATE UNIQUE INDEX ON #{tenant}.magic_links (token)", [])
  end

  @doc """
  Inserts a factory-built struct into a specific tenant schema.
  """
  def insert_in_tenant(tenant, factory, attrs \\ %{}) do
    struct = Factory.build(factory, attrs)
    Repo.insert!(struct, prefix: tenant)
  end

  @doc """
  Inserts multiple factory-built structs into a specific tenant schema.
  """
  def insert_list_in_tenant(tenant, count, factory, attrs \\ %{}) do
    Enum.map(1..count, fn _ ->
      struct = Factory.build(factory, attrs)
      Repo.insert!(struct, prefix: tenant)
    end)
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Sandbox.start_owner!(Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
