defmodule Wrt.PlatformTest do
  use Wrt.DataCase, async: true

  alias Wrt.Platform
  alias Wrt.Platform.Organisation

  # =============================================================================
  # Super Admin Functions
  # =============================================================================

  describe "get_super_admin/1" do
    test "returns super admin by id" do
      admin = Repo.insert!(build(:super_admin))
      assert Platform.get_super_admin(admin.id).id == admin.id
    end

    test "returns nil for non-existent id" do
      assert is_nil(Platform.get_super_admin(-1))
    end
  end

  describe "get_super_admin_by_email/1" do
    test "returns super admin by email" do
      admin = Repo.insert!(build(:super_admin, email: "findme@test.com"))
      assert Platform.get_super_admin_by_email("findme@test.com").id == admin.id
    end

    test "is case-insensitive" do
      admin = Repo.insert!(build(:super_admin, email: "case@test.com"))
      assert Platform.get_super_admin_by_email("CASE@test.com").id == admin.id
    end

    test "returns nil for non-existent email" do
      assert is_nil(Platform.get_super_admin_by_email("nope@test.com"))
    end
  end

  describe "create_super_admin/1" do
    test "creates a super admin with valid attrs" do
      attrs = %{name: "New Admin", email: "new@test.com", password: "password123"}

      assert {:ok, admin} = Platform.create_super_admin(attrs)
      assert admin.name == "New Admin"
      assert admin.email == "new@test.com"
      assert admin.password_hash != nil
    end

    test "returns error for missing required fields" do
      assert {:error, changeset} = Platform.create_super_admin(%{})
      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.email
    end

    test "returns error for short password" do
      attrs = %{name: "Admin", email: "admin@test.com", password: "short"}

      assert {:error, changeset} = Platform.create_super_admin(attrs)
      assert errors_on(changeset).password != nil
    end

    test "returns error for duplicate email" do
      attrs = %{name: "First", email: "dup@test.com", password: "password123"}
      {:ok, _} = Platform.create_super_admin(attrs)

      assert {:error, changeset} =
               Platform.create_super_admin(%{
                 name: "Second",
                 email: "dup@test.com",
                 password: "password123"
               })

      assert errors_on(changeset).email != nil
    end
  end

  describe "update_super_admin/2" do
    test "updates name and email" do
      admin = Repo.insert!(build(:super_admin))

      assert {:ok, updated} =
               Platform.update_super_admin(admin, %{name: "Updated", email: "updated@test.com"})

      assert updated.name == "Updated"
    end
  end

  describe "authenticate_super_admin/2" do
    test "returns {:ok, admin} with valid credentials" do
      admin = Repo.insert!(build(:super_admin, email: "auth@test.com"))

      assert {:ok, result} = Platform.authenticate_super_admin("auth@test.com", "password123")
      assert result.id == admin.id
    end

    test "returns {:error, :invalid_password} with wrong password" do
      Repo.insert!(build(:super_admin, email: "auth2@test.com"))

      assert {:error, :invalid_password} =
               Platform.authenticate_super_admin("auth2@test.com", "wrongpassword")
    end

    test "returns {:error, :not_found} for non-existent email" do
      assert {:error, :not_found} =
               Platform.authenticate_super_admin("nonexistent@test.com", "password123")
    end
  end

  # =============================================================================
  # Organisation Functions
  # =============================================================================

  describe "list_organisations/0" do
    test "returns empty list when no organisations" do
      assert Platform.list_organisations() == []
    end

    test "returns all organisations" do
      Repo.insert!(build(:organisation, name: "First Org"))
      Repo.insert!(build(:organisation, name: "Second Org"))

      result = Platform.list_organisations()
      assert length(result) == 2
    end
  end

  describe "list_organisations_by_status/1" do
    test "filters by pending status" do
      Repo.insert!(build(:organisation, status: "pending"))
      Repo.insert!(build(:approved_organisation))

      result = Platform.list_organisations_by_status("pending")
      assert length(result) == 1
      assert hd(result).status == "pending"
    end

    test "filters by approved status" do
      Repo.insert!(build(:organisation, status: "pending"))
      Repo.insert!(build(:approved_organisation))

      result = Platform.list_organisations_by_status("approved")
      assert length(result) == 1
      assert hd(result).status == "approved"
    end
  end

  describe "list_approved_organisations/0" do
    test "returns only approved organisations" do
      Repo.insert!(build(:organisation, status: "pending"))
      approved = Repo.insert!(build(:approved_organisation))

      result = Platform.list_approved_organisations()
      assert length(result) == 1
      assert hd(result).id == approved.id
    end
  end

  describe "list_pending_organisations/0" do
    test "returns only pending organisations" do
      pending = Repo.insert!(build(:organisation, status: "pending"))
      Repo.insert!(build(:approved_organisation))

      result = Platform.list_pending_organisations()
      assert length(result) == 1
      assert hd(result).id == pending.id
    end
  end

  describe "get_organisation/1 and get_organisation!/1" do
    test "get_organisation returns org by id" do
      org = Repo.insert!(build(:organisation))
      assert Platform.get_organisation(org.id).id == org.id
    end

    test "get_organisation returns nil for non-existent id" do
      assert is_nil(Platform.get_organisation(-1))
    end

    test "get_organisation! raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Platform.get_organisation!(-1)
      end
    end
  end

  describe "get_organisation_by_admin_email/1" do
    test "returns organisation by admin email" do
      org = Repo.insert!(build(:organisation, admin_email: "admin@findme.com"))
      assert Platform.get_organisation_by_admin_email("admin@findme.com").id == org.id
    end

    test "is case-insensitive" do
      org = Repo.insert!(build(:organisation, admin_email: "admin@case.com"))
      assert Platform.get_organisation_by_admin_email("ADMIN@CASE.COM").id == org.id
    end

    test "returns nil for non-existent email" do
      assert is_nil(Platform.get_organisation_by_admin_email("nope@example.com"))
    end
  end

  describe "get_organisation_by_slug/1" do
    test "returns organisation by slug" do
      org = Repo.insert!(build(:organisation, slug: "my-org"))
      assert Platform.get_organisation_by_slug("my-org").id == org.id
    end

    test "returns nil for non-existent slug" do
      assert is_nil(Platform.get_organisation_by_slug("nonexistent"))
    end
  end

  describe "register_organisation/1" do
    test "creates a pending organisation" do
      attrs = %{
        name: "New Org",
        admin_name: "Admin Person",
        admin_email: "admin@neworg.com"
      }

      assert {:ok, org} = Platform.register_organisation(attrs)
      assert org.status == "pending"
      assert org.slug != nil
      assert org.name == "New Org"
    end

    test "generates slug from name" do
      attrs = %{
        name: "My Great Organisation!",
        admin_name: "Admin",
        admin_email: "admin@org.com"
      }

      assert {:ok, org} = Platform.register_organisation(attrs)
      assert org.slug =~ ~r/^my-great-organisation/
    end

    test "returns error for missing required fields" do
      assert {:error, changeset} = Platform.register_organisation(%{})
      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.admin_name
      assert "can't be blank" in errors.admin_email
    end

    test "returns error for duplicate admin_email" do
      attrs = %{name: "Org 1", admin_name: "Admin", admin_email: "dup@org.com"}
      {:ok, _} = Platform.register_organisation(attrs)

      assert {:error, changeset} =
               Platform.register_organisation(%{
                 name: "Org 2",
                 admin_name: "Admin 2",
                 admin_email: "dup@org.com"
               })

      assert errors_on(changeset).admin_email != nil
    end
  end

  describe "reject_organisation/2" do
    test "rejects a pending organisation" do
      org = Repo.insert!(build(:organisation, status: "pending"))

      assert {:ok, rejected} = Platform.reject_organisation(org, "Not a valid org")
      assert rejected.status == "rejected"
      assert rejected.rejection_reason == "Not a valid org"
    end

    test "rejects without reason" do
      org = Repo.insert!(build(:organisation, status: "pending"))

      assert {:ok, rejected} = Platform.reject_organisation(org)
      assert rejected.status == "rejected"
    end
  end

  describe "suspend_organisation/3" do
    test "suspends an approved organisation" do
      org = Repo.insert!(build(:approved_organisation))
      admin = Repo.insert!(build(:super_admin))

      assert {:ok, suspended} =
               Platform.suspend_organisation(org, admin, "Terms violation")

      assert suspended.status == "suspended"
      assert suspended.suspended_at != nil
      assert suspended.suspended_by_id == admin.id
      assert suspended.suspension_reason == "Terms violation"
    end
  end

  describe "reactivate_organisation/1" do
    test "reactivates a suspended organisation" do
      admin = Repo.insert!(build(:super_admin))

      org =
        Repo.insert!(
          build(:approved_organisation,
            status: "suspended",
            suspended_at: DateTime.utc_now() |> DateTime.truncate(:second),
            suspended_by_id: admin.id
          )
        )

      assert {:ok, reactivated} = Platform.reactivate_organisation(org)
      assert reactivated.status == "approved"
    end
  end

  describe "count_organisations_by_status/0" do
    test "returns empty map when no organisations" do
      assert Platform.count_organisations_by_status() == %{}
    end

    test "counts organisations by status" do
      Repo.insert!(build(:organisation, status: "pending"))
      Repo.insert!(build(:organisation, status: "pending"))
      Repo.insert!(build(:approved_organisation))

      counts = Platform.count_organisations_by_status()
      assert counts["pending"] == 2
      assert counts["approved"] == 1
    end
  end

  describe "tenant_for_org/1" do
    test "returns tenant schema name" do
      org = %Organisation{id: 42}
      assert Platform.tenant_for_org(org) == "tenant_42"
    end
  end
end
