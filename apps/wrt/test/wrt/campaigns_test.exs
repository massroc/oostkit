defmodule Wrt.CampaignsTest do
  use Wrt.DataCase, async: true

  alias Wrt.Campaigns
  alias Wrt.Campaigns.Campaign

  # =============================================================================
  # Campaign CRUD
  # =============================================================================

  describe "list_campaigns/1" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "returns empty list when no campaigns exist", %{tenant: tenant} do
      assert Campaigns.list_campaigns(tenant) == []
    end

    test "returns all campaigns", %{tenant: tenant} do
      insert_in_tenant(tenant, :campaign, %{name: "First"})
      insert_in_tenant(tenant, :campaign, %{name: "Second"})

      result = Campaigns.list_campaigns(tenant)
      assert length(result) == 2
    end
  end

  describe "get_active_campaign/1" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "returns nil when no active campaign exists", %{tenant: tenant} do
      insert_in_tenant(tenant, :campaign, %{status: "draft"})
      assert is_nil(Campaigns.get_active_campaign(tenant))
    end

    test "returns the active campaign", %{tenant: tenant} do
      active = insert_in_tenant(tenant, :active_campaign)
      assert Campaigns.get_active_campaign(tenant).id == active.id
    end
  end

  describe "has_active_campaign?/1" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "returns false when no active campaign", %{tenant: tenant} do
      refute Campaigns.has_active_campaign?(tenant)
    end

    test "returns true when active campaign exists", %{tenant: tenant} do
      insert_in_tenant(tenant, :active_campaign)
      assert Campaigns.has_active_campaign?(tenant)
    end
  end

  describe "get_campaign/2 and get_campaign!/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      %{tenant: tenant, campaign: campaign}
    end

    test "get_campaign returns campaign by id", %{tenant: tenant, campaign: campaign} do
      assert Campaigns.get_campaign(tenant, campaign.id).id == campaign.id
    end

    test "get_campaign returns nil for non-existent id", %{tenant: tenant} do
      assert is_nil(Campaigns.get_campaign(tenant, -1))
    end

    test "get_campaign! raises for non-existent id", %{tenant: tenant} do
      assert_raise Ecto.NoResultsError, fn ->
        Campaigns.get_campaign!(tenant, -1)
      end
    end
  end

  describe "create_campaign/2" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "creates a campaign with valid attrs", %{tenant: tenant} do
      attrs = %{name: "New Campaign", description: "Desc", default_round_duration_days: 7}

      assert {:ok, campaign} = Campaigns.create_campaign(tenant, attrs)
      assert campaign.name == "New Campaign"
      assert campaign.status == "draft"
    end

    test "returns error when name is missing", %{tenant: tenant} do
      assert {:error, changeset} = Campaigns.create_campaign(tenant, %{})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns error when active campaign exists", %{tenant: tenant} do
      insert_in_tenant(tenant, :active_campaign)
      attrs = %{name: "Another Campaign"}

      assert {:error, :active_campaign_exists} = Campaigns.create_campaign(tenant, attrs)
    end
  end

  describe "update_campaign/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      %{tenant: tenant, campaign: campaign}
    end

    test "updates a draft campaign", %{tenant: tenant, campaign: campaign} do
      assert {:ok, updated} =
               Campaigns.update_campaign(tenant, campaign, %{name: "Updated Name"})

      assert updated.name == "Updated Name"
    end

    test "returns error for non-draft campaign", %{tenant: tenant} do
      active = insert_in_tenant(tenant, :active_campaign)

      assert {:error, :cannot_update_non_draft_campaign} =
               Campaigns.update_campaign(tenant, active, %{name: "Nope"})
    end
  end

  describe "delete_campaign/2" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "deletes a draft campaign", %{tenant: tenant} do
      campaign = insert_in_tenant(tenant, :campaign)
      assert {:ok, _} = Campaigns.delete_campaign(tenant, campaign)
      assert is_nil(Campaigns.get_campaign(tenant, campaign.id))
    end

    test "returns error for non-draft campaign", %{tenant: tenant} do
      active = insert_in_tenant(tenant, :active_campaign)

      assert {:error, :cannot_delete_non_draft_campaign} =
               Campaigns.delete_campaign(tenant, active)
    end
  end

  describe "change_campaign/2" do
    test "returns a changeset" do
      changeset = Campaigns.change_campaign(%Campaign{}, %{name: "Test"})
      assert %Ecto.Changeset{} = changeset
    end
  end

  # =============================================================================
  # Campaign State Machine
  # =============================================================================

  describe "start_campaign/2" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "starts a draft campaign", %{tenant: tenant} do
      campaign = insert_in_tenant(tenant, :campaign)

      assert {:ok, started} = Campaigns.start_campaign(tenant, campaign)
      assert started.status == "active"
      assert started.started_at != nil
    end

    test "returns error if campaign is not draft", %{tenant: tenant} do
      active = insert_in_tenant(tenant, :active_campaign)

      assert {:error, :campaign_not_draft} = Campaigns.start_campaign(tenant, active)
    end

    test "returns error if another active campaign exists", %{tenant: tenant} do
      _active = insert_in_tenant(tenant, :active_campaign)
      draft = insert_in_tenant(tenant, :campaign)

      assert {:error, :active_campaign_exists} = Campaigns.start_campaign(tenant, draft)
    end
  end

  describe "complete_campaign/2" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "completes an active campaign", %{tenant: tenant} do
      active = insert_in_tenant(tenant, :active_campaign)

      assert {:ok, completed} = Campaigns.complete_campaign(tenant, active)
      assert completed.status == "completed"
      assert completed.completed_at != nil
    end

    test "returns error if campaign is not active", %{tenant: tenant} do
      draft = insert_in_tenant(tenant, :campaign)

      assert {:error, :campaign_not_active} = Campaigns.complete_campaign(tenant, draft)
    end

    test "returns error for already completed campaign", %{tenant: tenant} do
      completed = insert_in_tenant(tenant, :completed_campaign)

      assert {:error, :campaign_not_active} = Campaigns.complete_campaign(tenant, completed)
    end
  end

  # =============================================================================
  # Campaign Admins
  # =============================================================================

  describe "list_campaign_admins/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      %{tenant: tenant, campaign: campaign}
    end

    test "returns empty list when no admins", %{tenant: tenant, campaign: campaign} do
      assert Campaigns.list_campaign_admins(tenant, campaign.id) == []
    end

    test "returns admins for the campaign", %{tenant: tenant, campaign: campaign} do
      admin =
        insert_in_tenant(tenant, :campaign_admin, %{campaign_id: campaign.id, name: "Alice"})

      result = Campaigns.list_campaign_admins(tenant, campaign.id)
      assert length(result) == 1
      assert hd(result).id == admin.id
    end

    test "does not return admins from other campaigns", %{tenant: tenant, campaign: campaign} do
      other_campaign = insert_in_tenant(tenant, :campaign)
      insert_in_tenant(tenant, :campaign_admin, %{campaign_id: other_campaign.id})

      assert Campaigns.list_campaign_admins(tenant, campaign.id) == []
    end
  end

  describe "get_campaign_admin/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      admin = insert_in_tenant(tenant, :campaign_admin, %{campaign_id: campaign.id})
      %{tenant: tenant, admin: admin}
    end

    test "returns admin by id", %{tenant: tenant, admin: admin} do
      assert Campaigns.get_campaign_admin(tenant, admin.id).id == admin.id
    end

    test "returns nil for non-existent id", %{tenant: tenant} do
      assert is_nil(Campaigns.get_campaign_admin(tenant, -1))
    end
  end

  describe "get_campaign_admin_by_email/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)

      admin =
        insert_in_tenant(tenant, :campaign_admin, %{
          campaign_id: campaign.id,
          email: "admin@test.com"
        })

      %{tenant: tenant, campaign: campaign, admin: admin}
    end

    test "finds admin by email (case-insensitive)", %{
      tenant: tenant,
      campaign: campaign,
      admin: admin
    } do
      assert Campaigns.get_campaign_admin_by_email(tenant, campaign.id, "ADMIN@test.com").id ==
               admin.id
    end

    test "returns nil for wrong campaign", %{tenant: tenant, admin: _admin} do
      other_campaign = insert_in_tenant(tenant, :campaign)

      assert is_nil(
               Campaigns.get_campaign_admin_by_email(tenant, other_campaign.id, "admin@test.com")
             )
    end
  end

  describe "invite_campaign_admin/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      %{tenant: tenant, campaign: campaign}
    end

    test "creates a campaign admin with valid attrs", %{tenant: tenant, campaign: campaign} do
      attrs = %{
        campaign_id: campaign.id,
        name: "New Admin",
        email: "new@test.com",
        password: "password123"
      }

      assert {:ok, admin} = Campaigns.invite_campaign_admin(tenant, attrs)
      assert admin.name == "New Admin"
      assert admin.email == "new@test.com"
    end

    test "returns error for missing fields", %{tenant: tenant} do
      assert {:error, changeset} = Campaigns.invite_campaign_admin(tenant, %{})
      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.email
    end
  end

  describe "remove_campaign_admin/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      admin = insert_in_tenant(tenant, :campaign_admin, %{campaign_id: campaign.id})
      %{tenant: tenant, admin: admin}
    end

    test "deletes the campaign admin", %{tenant: tenant, admin: admin} do
      assert {:ok, _} = Campaigns.remove_campaign_admin(tenant, admin)
      assert is_nil(Campaigns.get_campaign_admin(tenant, admin.id))
    end
  end

  describe "authenticate_campaign_admin/4" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)

      admin =
        insert_in_tenant(tenant, :campaign_admin, %{
          campaign_id: campaign.id,
          email: "auth@test.com"
        })

      %{tenant: tenant, campaign: campaign, admin: admin}
    end

    test "returns {:ok, admin} with valid credentials", %{
      tenant: tenant,
      campaign: campaign,
      admin: admin
    } do
      assert {:ok, result} =
               Campaigns.authenticate_campaign_admin(
                 tenant,
                 campaign.id,
                 "auth@test.com",
                 "password123"
               )

      assert result.id == admin.id
    end

    test "returns {:error, :invalid_password} with wrong password", %{
      tenant: tenant,
      campaign: campaign
    } do
      assert {:error, :invalid_password} =
               Campaigns.authenticate_campaign_admin(
                 tenant,
                 campaign.id,
                 "auth@test.com",
                 "wrongpassword"
               )
    end

    test "returns {:error, :not_found} for non-existent email", %{
      tenant: tenant,
      campaign: campaign
    } do
      assert {:error, :not_found} =
               Campaigns.authenticate_campaign_admin(
                 tenant,
                 campaign.id,
                 "nonexistent@test.com",
                 "password123"
               )
    end
  end
end
