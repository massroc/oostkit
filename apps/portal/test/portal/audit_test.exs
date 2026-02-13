defmodule Portal.AuditTest do
  use Portal.DataCase, async: true

  alias Portal.Audit

  describe "log/5" do
    test "creates an audit log entry" do
      user = Portal.AccountsFixtures.user_fixture()

      assert {:ok, log} =
               Audit.log(user, "tool.toggle", "tool", "workgroup_pulse",
                 changes: %{admin_enabled: true},
                 ip_address: "127.0.0.1"
               )

      assert log.actor_id == user.id
      assert log.actor_email == user.email
      assert log.action == "tool.toggle"
      assert log.entity_type == "tool"
      assert log.entity_id == "workgroup_pulse"
      assert log.changes == %{admin_enabled: true}
      assert log.ip_address == "127.0.0.1"
      assert log.inserted_at
    end

    test "creates entry without optional fields" do
      user = Portal.AccountsFixtures.user_fixture()

      assert {:ok, log} = Audit.log(user, "signups.export", "signup_export", nil)

      assert log.actor_id == user.id
      assert log.entity_id == nil
      assert log.changes == %{}
      assert log.ip_address == nil
    end

    test "converts entity_id to string" do
      user = Portal.AccountsFixtures.user_fixture()

      assert {:ok, log} = Audit.log(user, "user.create", "user", 42)
      assert log.entity_id == "42"
    end
  end

  describe "list_recent/1" do
    test "returns recent entries ordered by newest first" do
      user = Portal.AccountsFixtures.user_fixture()

      {:ok, _log1} = Audit.log(user, "tool.toggle", "tool", "t1")
      {:ok, _log2} = Audit.log(user, "user.create", "user", "u1")

      logs = Audit.list_recent()
      assert length(logs) == 2
      assert hd(logs).action == "user.create"
    end

    test "respects limit" do
      user = Portal.AccountsFixtures.user_fixture()

      for i <- 1..5 do
        Audit.log(user, "tool.toggle", "tool", "t#{i}")
      end

      assert length(Audit.list_recent(3)) == 3
    end
  end

  describe "list_for_entity/3" do
    test "filters by entity type and id" do
      user = Portal.AccountsFixtures.user_fixture()

      {:ok, _} = Audit.log(user, "tool.toggle", "tool", "t1")
      {:ok, _} = Audit.log(user, "tool.toggle", "tool", "t2")
      {:ok, _} = Audit.log(user, "user.create", "user", "u1")

      logs = Audit.list_for_entity("tool", "t1")
      assert length(logs) == 1
      assert hd(logs).entity_id == "t1"
    end
  end
end
