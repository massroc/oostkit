defmodule Wrt.OrgsTest do
  use Wrt.DataCase, async: true

  alias Wrt.Orgs
  alias Wrt.Orgs.OrgAdmin

  # =============================================================================
  # Org Admin CRUD
  # =============================================================================

  describe "list_org_admins/1" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "returns empty list when no admins exist", %{tenant: tenant} do
      assert Orgs.list_org_admins(tenant) == []
    end

    test "returns admins ordered by name", %{tenant: tenant} do
      insert_in_tenant(tenant, :org_admin, %{name: "Zoe"})
      insert_in_tenant(tenant, :org_admin, %{name: "Alice"})

      result = Orgs.list_org_admins(tenant)
      assert [%{name: "Alice"}, %{name: "Zoe"}] = result
    end
  end

  describe "get_org_admin/2 and get_org_admin!/2" do
    setup do
      tenant = create_test_tenant()
      admin = insert_in_tenant(tenant, :org_admin)
      %{tenant: tenant, admin: admin}
    end

    test "get_org_admin returns admin by id", %{tenant: tenant, admin: admin} do
      assert Orgs.get_org_admin(tenant, admin.id).id == admin.id
    end

    test "get_org_admin returns nil for non-existent id", %{tenant: tenant} do
      assert is_nil(Orgs.get_org_admin(tenant, -1))
    end

    test "get_org_admin! raises for non-existent id", %{tenant: tenant} do
      assert_raise Ecto.NoResultsError, fn ->
        Orgs.get_org_admin!(tenant, -1)
      end
    end
  end

  describe "get_org_admin_by_email/2" do
    setup do
      tenant = create_test_tenant()
      admin = insert_in_tenant(tenant, :org_admin, %{email: "findme@test.com"})
      %{tenant: tenant, admin: admin}
    end

    test "finds admin by email (case-insensitive)", %{tenant: tenant, admin: admin} do
      assert Orgs.get_org_admin_by_email(tenant, "FINDME@test.com").id == admin.id
    end

    test "returns nil for non-existent email", %{tenant: tenant} do
      assert is_nil(Orgs.get_org_admin_by_email(tenant, "nope@test.com"))
    end
  end

  describe "create_org_admin/2" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "creates an org admin with valid attrs", %{tenant: tenant} do
      attrs = %{name: "New Admin", email: "new@test.com", password: "password123"}

      assert {:ok, admin} = Orgs.create_org_admin(tenant, attrs)
      assert admin.name == "New Admin"
      assert admin.email == "new@test.com"
      assert admin.password_hash != nil
    end

    test "returns error for missing required fields", %{tenant: tenant} do
      assert {:error, changeset} = Orgs.create_org_admin(tenant, %{})
      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.email
    end

    test "returns error for short password", %{tenant: tenant} do
      attrs = %{name: "Admin", email: "admin@test.com", password: "short"}

      assert {:error, changeset} = Orgs.create_org_admin(tenant, attrs)
      assert errors_on(changeset).password != nil
    end

    test "returns error for duplicate email", %{tenant: tenant} do
      attrs = %{name: "First", email: "dup@test.com", password: "password123"}
      {:ok, _} = Orgs.create_org_admin(tenant, attrs)

      assert {:error, changeset} =
               Orgs.create_org_admin(tenant, %{
                 name: "Second",
                 email: "dup@test.com",
                 password: "password123"
               })

      assert errors_on(changeset).email != nil
    end
  end

  describe "update_org_admin/3" do
    setup do
      tenant = create_test_tenant()
      admin = insert_in_tenant(tenant, :org_admin)
      %{tenant: tenant, admin: admin}
    end

    test "updates name and email", %{tenant: tenant, admin: admin} do
      assert {:ok, updated} =
               Orgs.update_org_admin(tenant, admin, %{name: "Updated", email: "updated@test.com"})

      assert updated.name == "Updated"
      assert updated.email == "updated@test.com"
    end
  end

  describe "delete_org_admin/2" do
    setup do
      tenant = create_test_tenant()
      admin = insert_in_tenant(tenant, :org_admin)
      %{tenant: tenant, admin: admin}
    end

    test "deletes the org admin", %{tenant: tenant, admin: admin} do
      assert {:ok, _} = Orgs.delete_org_admin(tenant, admin)
      assert is_nil(Orgs.get_org_admin(tenant, admin.id))
    end
  end

  # =============================================================================
  # Authentication
  # =============================================================================

  describe "authenticate_org_admin/3" do
    setup do
      tenant = create_test_tenant()
      admin = insert_in_tenant(tenant, :org_admin, %{email: "auth@test.com"})
      %{tenant: tenant, admin: admin}
    end

    test "returns {:ok, admin} with valid credentials", %{tenant: tenant, admin: admin} do
      assert {:ok, result} = Orgs.authenticate_org_admin(tenant, "auth@test.com", "password123")
      assert result.id == admin.id
    end

    test "returns {:error, :invalid_password} with wrong password", %{tenant: tenant} do
      assert {:error, :invalid_password} =
               Orgs.authenticate_org_admin(tenant, "auth@test.com", "wrongpassword")
    end

    test "returns {:error, :not_found} for non-existent email", %{tenant: tenant} do
      assert {:error, :not_found} =
               Orgs.authenticate_org_admin(tenant, "nonexistent@test.com", "password123")
    end
  end

  describe "change_org_admin/2" do
    test "returns a changeset" do
      changeset = Orgs.change_org_admin(%OrgAdmin{}, %{name: "Test"})
      assert %Ecto.Changeset{} = changeset
    end
  end
end
