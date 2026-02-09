defmodule Wrt.RoundsTest do
  use Wrt.DataCase, async: true

  alias Wrt.People
  alias Wrt.Rounds

  # =============================================================================
  # Round CRUD
  # =============================================================================

  describe "list_rounds/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      %{tenant: tenant, campaign: campaign}
    end

    test "returns empty list when no rounds", %{tenant: tenant, campaign: campaign} do
      assert Rounds.list_rounds(tenant, campaign.id) == []
    end

    test "returns rounds ordered by round_number", %{tenant: tenant, campaign: campaign} do
      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 2})
      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      result = Rounds.list_rounds(tenant, campaign.id)
      assert [%{round_number: 1}, %{round_number: 2}] = result
    end

    test "only returns rounds for specified campaign", %{tenant: tenant, campaign: campaign} do
      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      other_campaign = insert_in_tenant(tenant, :campaign)
      insert_in_tenant(tenant, :round, %{campaign_id: other_campaign.id, round_number: 1})

      assert length(Rounds.list_rounds(tenant, campaign.id)) == 1
    end
  end

  describe "get_active_round/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      %{tenant: tenant, campaign: campaign}
    end

    test "returns nil when no active round", %{tenant: tenant, campaign: campaign} do
      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      assert is_nil(Rounds.get_active_round(tenant, campaign.id))
    end

    test "returns the active round", %{tenant: tenant, campaign: campaign} do
      active =
        insert_in_tenant(tenant, :active_round, %{campaign_id: campaign.id, round_number: 1})

      assert Rounds.get_active_round(tenant, campaign.id).id == active.id
    end
  end

  describe "get_round/2 and get_round!/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      %{tenant: tenant, round: round}
    end

    test "get_round returns round by id", %{tenant: tenant, round: round} do
      assert Rounds.get_round(tenant, round.id).id == round.id
    end

    test "get_round returns nil for non-existent id", %{tenant: tenant} do
      assert is_nil(Rounds.get_round(tenant, -1))
    end

    test "get_round! raises for non-existent id", %{tenant: tenant} do
      assert_raise Ecto.NoResultsError, fn ->
        Rounds.get_round!(tenant, -1)
      end
    end
  end

  describe "get_round_by_number/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      %{tenant: tenant, campaign: campaign, round: round}
    end

    test "returns round by campaign and number", %{
      tenant: tenant,
      campaign: campaign,
      round: round
    } do
      assert Rounds.get_round_by_number(tenant, campaign.id, 1).id == round.id
    end

    test "returns nil for non-existent round number", %{tenant: tenant, campaign: campaign} do
      assert is_nil(Rounds.get_round_by_number(tenant, campaign.id, 99))
    end
  end

  describe "next_round_number/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      %{tenant: tenant, campaign: campaign}
    end

    test "returns 1 when no rounds exist", %{tenant: tenant, campaign: campaign} do
      assert Rounds.next_round_number(tenant, campaign.id) == 1
    end

    test "returns next number after existing rounds", %{tenant: tenant, campaign: campaign} do
      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 2})

      assert Rounds.next_round_number(tenant, campaign.id) == 3
    end
  end

  describe "create_round/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      %{tenant: tenant, campaign: campaign}
    end

    test "creates a round with auto-incremented number", %{tenant: tenant, campaign: campaign} do
      assert {:ok, round} = Rounds.create_round(tenant, campaign.id)
      assert round.round_number == 1
      assert round.status == "pending"
      assert round.campaign_id == campaign.id
    end

    test "creates subsequent rounds with correct numbering", %{
      tenant: tenant,
      campaign: campaign
    } do
      {:ok, _r1} = Rounds.create_round(tenant, campaign.id)
      {:ok, r2} = Rounds.create_round(tenant, campaign.id)
      assert r2.round_number == 2
    end
  end

  # =============================================================================
  # Round Lifecycle
  # =============================================================================

  describe "start_round/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      # Create seed people who will be contacted
      seed1 = insert_in_tenant(tenant, :seed_person)
      seed2 = insert_in_tenant(tenant, :seed_person)

      %{tenant: tenant, campaign: campaign, round: round, seeds: [seed1, seed2]}
    end

    test "starts a round and creates contacts for seed people", %{
      tenant: tenant,
      round: round,
      seeds: seeds
    } do
      assert {:ok, {started_round, contacts}} = Rounds.start_round(tenant, round, 7)
      assert started_round.status == "active"
      assert started_round.started_at != nil
      assert started_round.deadline != nil
      assert length(contacts) == length(seeds)
    end

    test "sets deadline based on duration_days", %{tenant: tenant, round: round} do
      {:ok, {started, _contacts}} = Rounds.start_round(tenant, round, 7)

      expected_deadline = DateTime.utc_now() |> DateTime.add(7 * 24 * 60 * 60)
      diff = DateTime.diff(started.deadline, expected_deadline)
      assert abs(diff) < 5
    end
  end

  describe "close_round/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)

      active =
        insert_in_tenant(tenant, :active_round, %{campaign_id: campaign.id, round_number: 1})

      %{tenant: tenant, active_round: active}
    end

    test "closes an active round", %{tenant: tenant, active_round: round} do
      assert {:ok, closed} = Rounds.close_round(tenant, round)
      assert closed.status == "closed"
      assert closed.closed_at != nil
    end

    test "returns error for non-active round", %{tenant: tenant} do
      campaign = insert_in_tenant(tenant, :campaign)
      pending = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      assert {:error, :round_not_active} = Rounds.close_round(tenant, pending)
    end
  end

  describe "extend_round/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)

      active =
        insert_in_tenant(tenant, :active_round, %{campaign_id: campaign.id, round_number: 1})

      %{tenant: tenant, active_round: active}
    end

    test "extends an active round's deadline", %{tenant: tenant, active_round: round} do
      new_deadline =
        DateTime.utc_now() |> DateTime.add(14 * 24 * 60 * 60) |> DateTime.truncate(:second)

      assert {:ok, extended} = Rounds.extend_round(tenant, round, new_deadline)
      assert extended.deadline == new_deadline
    end

    test "returns error for non-active round", %{tenant: tenant} do
      campaign = insert_in_tenant(tenant, :campaign)
      pending = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      new_deadline = DateTime.utc_now() |> DateTime.add(7 * 24 * 60 * 60)
      assert {:error, :round_not_active} = Rounds.extend_round(tenant, pending, new_deadline)
    end
  end

  # =============================================================================
  # Contact Functions
  # =============================================================================

  describe "create_contact/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)
      %{tenant: tenant, round: round, person: person}
    end

    test "creates a contact", %{tenant: tenant, round: round, person: person} do
      assert {:ok, contact} =
               Rounds.create_contact(tenant, %{person_id: person.id, round_id: round.id})

      assert contact.person_id == person.id
      assert contact.round_id == round.id
      assert contact.email_status == "pending"
    end

    test "enforces unique person+round constraint", %{
      tenant: tenant,
      round: round,
      person: person
    } do
      attrs = %{person_id: person.id, round_id: round.id}
      {:ok, _} = Rounds.create_contact(tenant, attrs)

      assert {:error, _changeset} = Rounds.create_contact(tenant, attrs)
    end
  end

  describe "get_contact/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      {:ok, contact} =
        Rounds.create_contact(tenant, %{person_id: person.id, round_id: round.id})

      %{tenant: tenant, contact: contact}
    end

    test "returns contact with preloads", %{tenant: tenant, contact: contact} do
      result = Rounds.get_contact(tenant, contact.id)
      assert result.id == contact.id
      assert result.person != nil
      assert result.round != nil
    end
  end

  describe "get_contact_for_person/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      {:ok, contact} =
        Rounds.create_contact(tenant, %{person_id: person.id, round_id: round.id})

      %{tenant: tenant, round: round, person: person, contact: contact}
    end

    test "returns contact for person in round", %{
      tenant: tenant,
      round: round,
      person: person,
      contact: contact
    } do
      assert Rounds.get_contact_for_person(tenant, round.id, person.id).id == contact.id
    end

    test "returns nil for non-existent combination", %{tenant: tenant, round: round} do
      assert is_nil(Rounds.get_contact_for_person(tenant, round.id, -1))
    end
  end

  describe "list_contacts/2 and list_pending_contacts/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person1 = insert_in_tenant(tenant, :person)
      person2 = insert_in_tenant(tenant, :person)

      {:ok, c1} = Rounds.create_contact(tenant, %{person_id: person1.id, round_id: round.id})
      {:ok, _c2} = Rounds.create_contact(tenant, %{person_id: person2.id, round_id: round.id})

      # Mark one as responded
      {:ok, _} = Rounds.mark_responded(tenant, c1)

      %{tenant: tenant, round: round}
    end

    test "list_contacts returns all contacts for a round", %{tenant: tenant, round: round} do
      assert length(Rounds.list_contacts(tenant, round.id)) == 2
    end

    test "list_pending_contacts returns only unresponded contacts", %{
      tenant: tenant,
      round: round
    } do
      pending = Rounds.list_pending_contacts(tenant, round.id)
      assert length(pending) == 1
      assert Enum.all?(pending, &is_nil(&1.responded_at))
    end
  end

  describe "mark_responded/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      {:ok, contact} =
        Rounds.create_contact(tenant, %{person_id: person.id, round_id: round.id})

      %{tenant: tenant, contact: contact}
    end

    test "marks contact as responded", %{tenant: tenant, contact: contact} do
      assert {:ok, responded} = Rounds.mark_responded(tenant, contact)
      assert responded.responded_at != nil
    end
  end

  describe "update_email_status/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      {:ok, contact} =
        Rounds.create_contact(tenant, %{person_id: person.id, round_id: round.id})

      %{tenant: tenant, contact: contact}
    end

    test "updates delivered status", %{tenant: tenant, contact: contact} do
      assert {:ok, updated} = Rounds.update_email_status(tenant, contact.id, "delivered")
      assert updated.email_status == "delivered"
      assert updated.delivered_at != nil
    end

    test "updates opened status", %{tenant: tenant, contact: contact} do
      assert {:ok, updated} = Rounds.update_email_status(tenant, contact.id, "opened")
      assert updated.opened_at != nil
    end

    test "updates clicked status", %{tenant: tenant, contact: contact} do
      assert {:ok, updated} = Rounds.update_email_status(tenant, contact.id, "clicked")
      assert updated.clicked_at != nil
    end

    test "handles bounced status", %{tenant: tenant, contact: contact} do
      assert {:ok, updated} = Rounds.update_email_status(tenant, contact.id, "bounced")
      assert updated.email_status == "bounced"
    end

    test "handles spam status", %{tenant: tenant, contact: contact} do
      assert {:ok, updated} = Rounds.update_email_status(tenant, contact.id, "spam")
      assert updated.email_status == "spam"
    end

    test "returns error for non-existent contact", %{tenant: tenant} do
      assert {:error, :not_found} = Rounds.update_email_status(tenant, -1, "delivered")
    end

    test "returns error for invalid status", %{tenant: tenant, contact: contact} do
      assert {:error, :invalid_status} =
               Rounds.update_email_status(tenant, contact.id, "invalid")
    end
  end

  describe "count_contacts/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      %{tenant: tenant, round: round}
    end

    test "returns zero counts when no contacts", %{tenant: tenant, round: round} do
      assert %{total: 0, responded: 0, pending: 0} = Rounds.count_contacts(tenant, round.id)
    end

    test "counts contacts correctly", %{tenant: tenant, round: round} do
      person1 = insert_in_tenant(tenant, :person)
      person2 = insert_in_tenant(tenant, :person)
      person3 = insert_in_tenant(tenant, :person)

      {:ok, c1} = Rounds.create_contact(tenant, %{person_id: person1.id, round_id: round.id})
      {:ok, _c2} = Rounds.create_contact(tenant, %{person_id: person2.id, round_id: round.id})
      {:ok, _c3} = Rounds.create_contact(tenant, %{person_id: person3.id, round_id: round.id})
      {:ok, _} = Rounds.mark_responded(tenant, c1)

      assert %{total: 3, responded: 1, pending: 2} = Rounds.count_contacts(tenant, round.id)
    end
  end

  # =============================================================================
  # Single-Ask Constraint
  # =============================================================================

  describe "get_eligible_people/2 (round 1 - seed group)" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      seed1 = insert_in_tenant(tenant, :seed_person)
      seed2 = insert_in_tenant(tenant, :seed_person)
      _nominated = insert_in_tenant(tenant, :person)

      %{tenant: tenant, campaign: campaign, round: round, seeds: [seed1, seed2]}
    end

    test "returns seed people for round 1", %{tenant: tenant, round: round, seeds: seeds} do
      eligible = Rounds.get_eligible_people(tenant, round)
      assert length(eligible) == length(seeds)
      assert Enum.all?(eligible, &(&1.source == "seed"))
    end

    test "excludes previously contacted seed people", %{
      tenant: tenant,
      round: round,
      seeds: [seed1 | _]
    } do
      # Contact seed1 in this round
      Rounds.create_contact(tenant, %{person_id: seed1.id, round_id: round.id})

      eligible = Rounds.get_eligible_people(tenant, round)
      refute Enum.any?(eligible, &(&1.id == seed1.id))
    end
  end

  describe "get_eligible_people/2 (subsequent rounds - nominees)" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round1 = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      round2 = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 2})

      seed = insert_in_tenant(tenant, :seed_person)
      nominee = insert_in_tenant(tenant, :person, %{name: "Nominee"})

      # Seed was contacted in round 1
      Rounds.create_contact(tenant, %{person_id: seed.id, round_id: round1.id})

      # Seed nominated someone in round 1
      People.create_nomination(tenant, %{
        round_id: round1.id,
        nominator_id: seed.id,
        nominee_id: nominee.id
      })

      %{tenant: tenant, round2: round2, seed: seed, nominee: nominee}
    end

    test "returns nominees from previous round", %{
      tenant: tenant,
      round2: round2,
      nominee: nominee
    } do
      eligible = Rounds.get_eligible_people(tenant, round2)
      assert length(eligible) == 1
      assert hd(eligible).id == nominee.id
    end

    test "excludes nominees who were already contacted", %{
      tenant: tenant,
      round2: round2,
      nominee: nominee
    } do
      # Contact the nominee in round 1 (simulating they were already contacted)
      round1 = Rounds.get_round_by_number(tenant, round2.campaign_id, 1)
      Rounds.create_contact(tenant, %{person_id: nominee.id, round_id: round1.id})

      eligible = Rounds.get_eligible_people(tenant, round2)
      assert eligible == []
    end
  end

  describe "get_all_contacted_person_ids/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)
      Rounds.create_contact(tenant, %{person_id: person.id, round_id: round.id})

      %{tenant: tenant, campaign: campaign, person: person}
    end

    test "returns set of contacted person ids", %{
      tenant: tenant,
      campaign: campaign,
      person: person
    } do
      ids = Rounds.get_all_contacted_person_ids(tenant, campaign.id)
      assert MapSet.member?(ids, person.id)
    end
  end

  describe "person_contacted?/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)
      Rounds.create_contact(tenant, %{person_id: person.id, round_id: round.id})

      %{tenant: tenant, campaign: campaign, person: person}
    end

    test "returns true for contacted person", %{
      tenant: tenant,
      campaign: campaign,
      person: person
    } do
      assert Rounds.person_contacted?(tenant, campaign.id, person.id)
    end

    test "returns false for non-contacted person", %{tenant: tenant, campaign: campaign} do
      refute Rounds.person_contacted?(tenant, campaign.id, -1)
    end
  end
end
