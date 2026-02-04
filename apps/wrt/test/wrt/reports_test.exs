defmodule Wrt.ReportsTest do
  use Wrt.DataCase, async: true

  alias Wrt.Reports
  alias Wrt.Rounds.Contact
  alias Wrt.People.Nomination

  describe "get_campaign_stats/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)

      %{tenant: tenant, campaign: campaign}
    end

    test "returns all stat categories", %{tenant: tenant, campaign: campaign} do
      stats = Reports.get_campaign_stats(tenant, campaign.id)

      assert Map.has_key?(stats, :rounds)
      assert Map.has_key?(stats, :contacts)
      assert Map.has_key?(stats, :nominations)
      assert Map.has_key?(stats, :convergence)
    end
  end

  describe "get_rounds_summary/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)

      %{tenant: tenant, campaign: campaign}
    end

    test "returns zero counts when no rounds exist", %{tenant: tenant, campaign: campaign} do
      summary = Reports.get_rounds_summary(tenant, campaign.id)

      assert summary.total == 0
      assert summary.active == 0
      assert summary.closed == 0
      assert summary.pending == 0
    end

    test "counts rounds by status", %{tenant: tenant, campaign: campaign} do
      # Create rounds with different statuses
      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1, status: "pending"})
      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 2, status: "active"})
      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 3, status: "active"})
      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 4, status: "closed"})

      summary = Reports.get_rounds_summary(tenant, campaign.id)

      assert summary.total == 4
      assert summary.pending == 1
      assert summary.active == 2
      assert summary.closed == 1
    end

    test "only counts rounds for the specified campaign", %{tenant: tenant, campaign: campaign} do
      other_campaign = insert_in_tenant(tenant, :campaign)

      insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      insert_in_tenant(tenant, :round, %{campaign_id: other_campaign.id, round_number: 1})

      summary = Reports.get_rounds_summary(tenant, campaign.id)

      assert summary.total == 1
    end
  end

  describe "get_contacts_summary/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      %{tenant: tenant, campaign: campaign, round: round}
    end

    test "returns zero counts when no contacts exist", %{tenant: tenant, campaign: campaign} do
      summary = Reports.get_contacts_summary(tenant, campaign.id)

      assert summary.total == 0
      assert summary.invited == 0
      assert summary.responded == 0
      assert summary.response_rate == 0.0
    end

    test "counts contacts by email status", %{tenant: tenant, campaign: campaign, round: round} do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      # Create contacts with various statuses
      person1 = insert_in_tenant(tenant, :person)
      person2 = insert_in_tenant(tenant, :person)
      person3 = insert_in_tenant(tenant, :person)

      # Not invited
      Wrt.Repo.insert!(%Contact{person_id: person1.id, round_id: round.id}, prefix: tenant)

      # Invited and delivered
      Wrt.Repo.insert!(
        %Contact{
          person_id: person2.id,
          round_id: round.id,
          invited_at: now,
          delivered_at: now,
          opened_at: now
        },
        prefix: tenant
      )

      # Invited, delivered, and responded
      Wrt.Repo.insert!(
        %Contact{
          person_id: person3.id,
          round_id: round.id,
          invited_at: now,
          delivered_at: now,
          opened_at: now,
          clicked_at: now,
          responded_at: now
        },
        prefix: tenant
      )

      summary = Reports.get_contacts_summary(tenant, campaign.id)

      assert summary.total == 3
      assert summary.invited == 2
      assert summary.delivered == 2
      assert summary.opened == 2
      assert summary.clicked == 1
      assert summary.responded == 1
    end

    test "calculates response rate correctly", %{tenant: tenant, campaign: campaign, round: round} do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      # Create 10 contacts, 3 responded
      for i <- 1..10 do
        person = insert_in_tenant(tenant, :person)

        if i <= 3 do
          Wrt.Repo.insert!(
            %Contact{
              person_id: person.id,
              round_id: round.id,
              invited_at: now,
              responded_at: now
            },
            prefix: tenant
          )
        else
          Wrt.Repo.insert!(
            %Contact{person_id: person.id, round_id: round.id, invited_at: now},
            prefix: tenant
          )
        end
      end

      summary = Reports.get_contacts_summary(tenant, campaign.id)

      assert summary.response_rate == 30.0
    end
  end

  describe "get_nominations_summary/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      %{tenant: tenant, campaign: campaign, round: round}
    end

    test "returns zero counts when no nominations exist", %{tenant: tenant, campaign: campaign} do
      summary = Reports.get_nominations_summary(tenant, campaign.id)

      assert summary.total == 0
      assert summary.unique_nominees == 0
      assert summary.unique_nominators == 0
      assert summary.avg_per_nominator == 0.0
    end

    test "counts nominations correctly", %{tenant: tenant, campaign: campaign, round: round} do
      nominator1 = insert_in_tenant(tenant, :person)
      nominator2 = insert_in_tenant(tenant, :person)
      nominee1 = insert_in_tenant(tenant, :person)
      nominee2 = insert_in_tenant(tenant, :person)
      nominee3 = insert_in_tenant(tenant, :person)

      # Nominator1 nominates nominee1 and nominee2
      Wrt.Repo.insert!(
        %Nomination{round_id: round.id, nominator_id: nominator1.id, nominee_id: nominee1.id},
        prefix: tenant
      )

      Wrt.Repo.insert!(
        %Nomination{round_id: round.id, nominator_id: nominator1.id, nominee_id: nominee2.id},
        prefix: tenant
      )

      # Nominator2 nominates nominee1 (duplicate) and nominee3
      Wrt.Repo.insert!(
        %Nomination{round_id: round.id, nominator_id: nominator2.id, nominee_id: nominee1.id},
        prefix: tenant
      )

      Wrt.Repo.insert!(
        %Nomination{round_id: round.id, nominator_id: nominator2.id, nominee_id: nominee3.id},
        prefix: tenant
      )

      summary = Reports.get_nominations_summary(tenant, campaign.id)

      assert summary.total == 4
      assert summary.unique_nominees == 3
      assert summary.unique_nominators == 2
      assert summary.avg_per_nominator == 2.0
    end
  end

  describe "get_convergence_stats/1" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      %{tenant: tenant, round: round}
    end

    test "returns zero stats when no nominations exist", %{tenant: tenant} do
      stats = Reports.get_convergence_stats(tenant)

      assert stats.max == 0
      assert stats.avg == 0.0
      assert stats.median == 0
      assert stats.top_5_threshold == 0
      assert stats.distribution == []
    end

    test "calculates convergence metrics correctly", %{tenant: tenant, round: round} do
      nominators = for _ <- 1..5, do: insert_in_tenant(tenant, :person)
      nominees = for _ <- 1..5, do: insert_in_tenant(tenant, :person)

      # Create nominations:
      # nominee1 gets 5 nominations
      # nominee2 gets 3 nominations
      # nominee3 gets 2 nominations
      # nominee4 gets 1 nomination
      # nominee5 gets 1 nomination
      nominations_counts = [5, 3, 2, 1, 1]

      Enum.zip(nominees, nominations_counts)
      |> Enum.each(fn {nominee, count} ->
        nominators
        |> Enum.take(count)
        |> Enum.each(fn nominator ->
          Wrt.Repo.insert!(
            %Nomination{round_id: round.id, nominator_id: nominator.id, nominee_id: nominee.id},
            prefix: tenant
          )
        end)
      end)

      stats = Reports.get_convergence_stats(tenant)

      assert stats.max == 5
      assert stats.avg == 2.4
      # Median of [5, 3, 2, 1, 1] sorted desc is 2
      assert stats.median == 2
      # Top 5 threshold (5th element in sorted desc list)
      assert stats.top_5_threshold == 1
    end
  end

  describe "get_round_stats/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      %{tenant: tenant, round: round}
    end

    test "returns all stat categories", %{tenant: tenant, round: round} do
      stats = Reports.get_round_stats(tenant, round.id)

      assert Map.has_key?(stats, :contacts)
      assert Map.has_key?(stats, :nominations)
      assert Map.has_key?(stats, :email_funnel)
    end

    test "calculates round-specific contact stats", %{tenant: tenant, round: round} do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      # Create some contacts
      for i <- 1..5 do
        person = insert_in_tenant(tenant, :person)

        if i <= 2 do
          Wrt.Repo.insert!(
            %Contact{person_id: person.id, round_id: round.id, responded_at: now},
            prefix: tenant
          )
        else
          Wrt.Repo.insert!(
            %Contact{person_id: person.id, round_id: round.id},
            prefix: tenant
          )
        end
      end

      stats = Reports.get_round_stats(tenant, round.id)

      assert stats.contacts.total == 5
      assert stats.contacts.responded == 2
      assert stats.contacts.pending == 3
      assert stats.contacts.response_rate == 40.0
    end
  end

  describe "get_top_nominees/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      %{tenant: tenant, round: round}
    end

    test "returns empty list when no nominations exist", %{tenant: tenant} do
      assert Reports.get_top_nominees(tenant) == []
    end

    test "returns nominees ordered by nomination count", %{tenant: tenant, round: round} do
      nominators = for _ <- 1..5, do: insert_in_tenant(tenant, :person)
      top_nominee = insert_in_tenant(tenant, :person, %{name: "Top Person"})
      second_nominee = insert_in_tenant(tenant, :person, %{name: "Second Person"})

      # Top nominee gets 5 nominations
      Enum.each(nominators, fn nominator ->
        Wrt.Repo.insert!(
          %Nomination{round_id: round.id, nominator_id: nominator.id, nominee_id: top_nominee.id},
          prefix: tenant
        )
      end)

      # Second nominee gets 3 nominations
      nominators |> Enum.take(3) |> Enum.each(fn nominator ->
        Wrt.Repo.insert!(
          %Nomination{round_id: round.id, nominator_id: nominator.id, nominee_id: second_nominee.id},
          prefix: tenant
        )
      end)

      result = Reports.get_top_nominees(tenant, 2)

      assert length(result) == 2
      assert hd(result).name == "Top Person"
      assert hd(result).nomination_count == 5
      assert Enum.at(result, 1).name == "Second Person"
      assert Enum.at(result, 1).nomination_count == 3
    end

    test "respects the limit parameter", %{tenant: tenant, round: round} do
      nominator = insert_in_tenant(tenant, :person)

      for _ <- 1..10 do
        nominee = insert_in_tenant(tenant, :person)

        Wrt.Repo.insert!(
          %Nomination{round_id: round.id, nominator_id: nominator.id, nominee_id: nominee.id},
          prefix: tenant
        )
      end

      assert length(Reports.get_top_nominees(tenant, 5)) == 5
      assert length(Reports.get_top_nominees(tenant, 10)) == 10
    end
  end

  describe "get_top_nominators/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})

      %{tenant: tenant, round: round}
    end

    test "returns empty list when no nominations exist", %{tenant: tenant} do
      assert Reports.get_top_nominators(tenant) == []
    end

    test "returns nominators ordered by nominations made", %{tenant: tenant, round: round} do
      top_nominator = insert_in_tenant(tenant, :person, %{name: "Active Nominator"})
      second_nominator = insert_in_tenant(tenant, :person, %{name: "Less Active"})
      nominees = for _ <- 1..5, do: insert_in_tenant(tenant, :person)

      # Top nominator makes 5 nominations
      Enum.each(nominees, fn nominee ->
        Wrt.Repo.insert!(
          %Nomination{round_id: round.id, nominator_id: top_nominator.id, nominee_id: nominee.id},
          prefix: tenant
        )
      end)

      # Second nominator makes 2 nominations
      nominees |> Enum.take(2) |> Enum.each(fn nominee ->
        Wrt.Repo.insert!(
          %Nomination{round_id: round.id, nominator_id: second_nominator.id, nominee_id: nominee.id},
          prefix: tenant
        )
      end)

      result = Reports.get_top_nominators(tenant, 2)

      assert length(result) == 2
      assert hd(result).name == "Active Nominator"
      assert hd(result).nominations_made == 5
      assert Enum.at(result, 1).name == "Less Active"
      assert Enum.at(result, 1).nominations_made == 2
    end
  end
end
