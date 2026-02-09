defmodule Wrt.AuthTest do
  use Wrt.DataCase, async: true

  alias Wrt.Auth
  alias Wrt.Platform.SuperAdmin

  # =============================================================================
  # Super Admin Authentication
  # =============================================================================

  describe "authenticate_super_admin/2" do
    test "delegates to Platform and returns {:ok, admin}" do
      admin = Repo.insert!(build(:super_admin, email: "auth@test.com"))

      assert {:ok, result} = Auth.authenticate_super_admin("auth@test.com", "password123")
      assert result.id == admin.id
    end

    test "returns {:error, :invalid_password} with wrong password" do
      Repo.insert!(build(:super_admin, email: "wrong@test.com"))

      assert {:error, :invalid_password} =
               Auth.authenticate_super_admin("wrong@test.com", "badpassword")
    end

    test "returns {:error, :not_found} for non-existent email" do
      assert {:error, :not_found} =
               Auth.authenticate_super_admin("nobody@test.com", "password123")
    end
  end

  describe "get_super_admin/1" do
    test "returns super admin by id" do
      admin = Repo.insert!(build(:super_admin))
      assert Auth.get_super_admin(admin.id).id == admin.id
    end

    test "returns nil for non-existent id" do
      assert is_nil(Auth.get_super_admin(-1))
    end
  end

  describe "generate_super_admin_session_token/1" do
    test "generates a token and returns admin id" do
      admin = %SuperAdmin{id: 42, name: "Test", email: "test@test.com"}

      {token, admin_id} = Auth.generate_super_admin_session_token(admin)
      assert is_binary(token)
      assert byte_size(token) > 20
      assert admin_id == 42
    end
  end

  describe "verify_super_admin_session_token/2" do
    test "returns {:ok, admin} when admin exists" do
      admin = Repo.insert!(build(:super_admin))
      {token, admin_id} = Auth.generate_super_admin_session_token(admin)

      assert {:ok, result} = Auth.verify_super_admin_session_token(token, admin_id)
      assert result.id == admin.id
    end

    test "returns {:error, :not_found} when admin doesn't exist" do
      assert {:error, :not_found} =
               Auth.verify_super_admin_session_token("some-token", -1)
    end

    test "returns {:error, :invalid_token} for nil token" do
      assert {:error, :invalid_token} = Auth.verify_super_admin_session_token(nil, 1)
    end
  end

  # =============================================================================
  # Org Admin Authentication
  # =============================================================================

  describe "authenticate_org_admin/3" do
    setup do
      tenant = create_test_tenant()
      admin = insert_in_tenant(tenant, :org_admin, %{email: "orgauth@test.com"})
      %{tenant: tenant, admin: admin}
    end

    test "delegates to Orgs and returns {:ok, admin}", %{tenant: tenant, admin: admin} do
      assert {:ok, result} =
               Auth.authenticate_org_admin(tenant, "orgauth@test.com", "password123")

      assert result.id == admin.id
    end

    test "returns {:error, :invalid_password} with wrong password", %{tenant: tenant} do
      assert {:error, :invalid_password} =
               Auth.authenticate_org_admin(tenant, "orgauth@test.com", "wrongpassword")
    end

    test "returns {:error, :not_found} for non-existent email", %{tenant: tenant} do
      assert {:error, :not_found} =
               Auth.authenticate_org_admin(tenant, "nobody@test.com", "password123")
    end
  end

  describe "get_org_admin/2" do
    setup do
      tenant = create_test_tenant()
      admin = insert_in_tenant(tenant, :org_admin)
      %{tenant: tenant, admin: admin}
    end

    test "returns org admin by tenant and id", %{tenant: tenant, admin: admin} do
      assert Auth.get_org_admin(tenant, admin.id).id == admin.id
    end

    test "returns nil for non-existent id", %{tenant: tenant} do
      assert is_nil(Auth.get_org_admin(tenant, -1))
    end
  end
end
