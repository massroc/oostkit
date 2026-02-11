defmodule Wrt.PeopleTest do
  use Wrt.DataCase, async: true

  alias Wrt.People

  # =============================================================================
  # Person CRUD
  # =============================================================================

  describe "list_people/1" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "returns empty list when no people exist", %{tenant: tenant} do
      assert People.list_people(tenant) == []
    end

    test "returns people ordered by name", %{tenant: tenant} do
      insert_in_tenant(tenant, :person, %{name: "Zoe"})
      insert_in_tenant(tenant, :person, %{name: "Alice"})

      result = People.list_people(tenant)
      assert [%{name: "Alice"}, %{name: "Zoe"}] = result
    end
  end

  describe "list_seed_people/1" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "returns only seed people", %{tenant: tenant} do
      insert_in_tenant(tenant, :seed_person, %{name: "Seed Alice"})
      insert_in_tenant(tenant, :person, %{name: "Nominated Bob"})

      result = People.list_seed_people(tenant)
      assert length(result) == 1
      assert hd(result).name == "Seed Alice"
    end
  end

  describe "list_nominated_people/1" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "returns only nominated people", %{tenant: tenant} do
      insert_in_tenant(tenant, :seed_person, %{name: "Seed Alice"})
      insert_in_tenant(tenant, :person, %{name: "Nominated Bob"})

      result = People.list_nominated_people(tenant)
      assert length(result) == 1
      assert hd(result).name == "Nominated Bob"
    end
  end

  describe "get_person!/2" do
    setup do
      tenant = create_test_tenant()
      person = insert_in_tenant(tenant, :person)
      %{tenant: tenant, person: person}
    end

    test "returns person by id", %{tenant: tenant, person: person} do
      assert People.get_person!(tenant, person.id).id == person.id
    end

    test "raises for non-existent id", %{tenant: tenant} do
      assert_raise Ecto.NoResultsError, fn ->
        People.get_person!(tenant, -1)
      end
    end
  end

  describe "get_person_by_email/2" do
    setup do
      tenant = create_test_tenant()
      person = insert_in_tenant(tenant, :person, %{email: "findme@test.com"})
      %{tenant: tenant, person: person}
    end

    test "finds person by email", %{tenant: tenant, person: person} do
      assert People.get_person_by_email(tenant, "findme@test.com").id == person.id
    end

    test "returns nil for non-existent email", %{tenant: tenant} do
      assert is_nil(People.get_person_by_email(tenant, "nope@test.com"))
    end
  end

  describe "create_seed_person/2" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "creates a seed person", %{tenant: tenant} do
      attrs = %{name: "Seed Person", email: "seed@test.com"}

      assert {:ok, person} = People.create_seed_person(tenant, attrs)
      assert person.source == "seed"
      assert person.name == "Seed Person"
    end

    test "returns error for duplicate email", %{tenant: tenant} do
      attrs = %{name: "First", email: "dup@test.com"}
      {:ok, _} = People.create_seed_person(tenant, attrs)

      assert {:error, _changeset} =
               People.create_seed_person(tenant, %{name: "Second", email: "dup@test.com"})
    end

    test "returns error for missing fields", %{tenant: tenant} do
      assert {:error, changeset} = People.create_seed_person(tenant, %{})
      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.email
    end
  end

  describe "create_nominated_person/2" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "creates a nominated person", %{tenant: tenant} do
      attrs = %{name: "Nominated Person", email: "nom@test.com"}

      assert {:ok, person} = People.create_nominated_person(tenant, attrs)
      assert person.source == "nominated"
    end
  end

  describe "get_or_create_person/2" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "returns existing person when email exists", %{tenant: tenant} do
      existing = insert_in_tenant(tenant, :person, %{email: "exists@test.com"})

      assert {:ok, person} =
               People.get_or_create_person(tenant, %{name: "Different", email: "exists@test.com"})

      assert person.id == existing.id
    end

    test "creates new person when email doesn't exist", %{tenant: tenant} do
      assert {:ok, person} =
               People.get_or_create_person(tenant, %{name: "New", email: "new@test.com"})

      assert person.source == "nominated"
    end
  end

  describe "delete_person/2" do
    setup do
      tenant = create_test_tenant()
      person = insert_in_tenant(tenant, :person)
      %{tenant: tenant, person: person}
    end

    test "deletes the person", %{tenant: tenant, person: person} do
      assert {:ok, _} = People.delete_person(tenant, person)
      assert is_nil(Wrt.Repo.get(Wrt.People.Person, person.id, prefix: tenant))
    end
  end

  describe "count_people_by_source/1" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "returns empty map when no people", %{tenant: tenant} do
      assert People.count_people_by_source(tenant) == %{}
    end

    test "counts people by source", %{tenant: tenant} do
      insert_in_tenant(tenant, :seed_person)
      insert_in_tenant(tenant, :seed_person)
      insert_in_tenant(tenant, :person)

      counts = People.count_people_by_source(tenant)
      assert counts["seed"] == 2
      assert counts["nominated"] == 1
    end
  end

  # =============================================================================
  # CSV Parsing & Import
  # =============================================================================

  describe "parse_seed_csv/1" do
    test "parses valid CSV with name and email columns" do
      csv = "name,email\nAlice,alice@test.com\nBob,bob@test.com"

      assert {:ok, people} = People.parse_seed_csv(csv)
      assert length(people) == 2
      assert hd(people).name == "Alice"
      assert hd(people).email == "alice@test.com"
      assert hd(people).valid == true
    end

    test "handles case-insensitive headers" do
      csv = "Name,Email\nAlice,alice@test.com"

      assert {:ok, [person]} = People.parse_seed_csv(csv)
      assert person.name == "Alice"
    end

    test "accepts alternative header names" do
      csv = "Full Name,Email Address\nAlice,alice@test.com"

      assert {:ok, [person]} = People.parse_seed_csv(csv)
      assert person.name == "Alice"
    end

    test "returns error when name column is missing" do
      csv = "email\nalice@test.com"

      assert {:error, "CSV must have a 'name' column"} = People.parse_seed_csv(csv)
    end

    test "returns error when email column is missing" do
      csv = "name\nAlice"

      assert {:error, "CSV must have an 'email' column"} = People.parse_seed_csv(csv)
    end

    test "marks rows with empty data as invalid" do
      csv = "name,email\n,alice@test.com\nBob,"

      assert {:ok, people} = People.parse_seed_csv(csv)
      assert Enum.all?(people, &(&1.valid == false))
    end

    test "marks rows with invalid email as invalid" do
      csv = "name,email\nAlice,not-an-email"

      assert {:ok, [person]} = People.parse_seed_csv(csv)
      assert person.valid == false
    end

    test "tracks line numbers starting from 2" do
      csv = "name,email\nAlice,alice@test.com\nBob,bob@test.com"

      assert {:ok, people} = People.parse_seed_csv(csv)
      assert Enum.at(people, 0).line == 2
      assert Enum.at(people, 1).line == 3
    end
  end

  describe "import_seed_people/2" do
    setup do
      tenant = create_test_tenant()
      %{tenant: tenant}
    end

    test "imports valid people", %{tenant: tenant} do
      parsed = [
        %{name: "Alice", email: "alice@test.com", line: 2, valid: true},
        %{name: "Bob", email: "bob@test.com", line: 3, valid: true}
      ]

      assert {:ok, result} = People.import_seed_people(tenant, parsed)
      assert result.imported == 2
      assert result.skipped == 0
      assert result.errors == []
    end

    test "skips invalid rows", %{tenant: tenant} do
      parsed = [
        %{name: "Alice", email: "alice@test.com", line: 2, valid: true},
        %{name: "", email: "", line: 3, valid: false}
      ]

      assert {:ok, result} = People.import_seed_people(tenant, parsed)
      assert result.imported == 1
      assert length(result.errors) == 1
      assert hd(result.errors) =~ "Line 3"
    end

    test "skips duplicate emails", %{tenant: tenant} do
      insert_in_tenant(tenant, :person, %{email: "exists@test.com"})

      parsed = [
        %{name: "Dupe", email: "exists@test.com", line: 2, valid: true}
      ]

      assert {:ok, result} = People.import_seed_people(tenant, parsed)
      assert result.skipped == 1
    end
  end

  # =============================================================================
  # Nominations
  # =============================================================================

  describe "create_nomination/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      nominator = insert_in_tenant(tenant, :person)
      nominee = insert_in_tenant(tenant, :person)

      %{tenant: tenant, round: round, nominator: nominator, nominee: nominee}
    end

    test "creates a nomination", %{
      tenant: tenant,
      round: round,
      nominator: nominator,
      nominee: nominee
    } do
      attrs = %{round_id: round.id, nominator_id: nominator.id, nominee_id: nominee.id}

      assert {:ok, nomination} = People.create_nomination(tenant, attrs)
      assert nomination.round_id == round.id
      assert nomination.nominator_id == nominator.id
      assert nomination.nominee_id == nominee.id
    end

    test "returns error for self-nomination", %{
      tenant: tenant,
      round: round,
      nominator: nominator
    } do
      attrs = %{round_id: round.id, nominator_id: nominator.id, nominee_id: nominator.id}

      assert {:error, changeset} = People.create_nomination(tenant, attrs)
      assert errors_on(changeset).nominee_id != nil
    end

    test "returns error for duplicate nomination", %{
      tenant: tenant,
      round: round,
      nominator: nominator,
      nominee: nominee
    } do
      attrs = %{round_id: round.id, nominator_id: nominator.id, nominee_id: nominee.id}
      {:ok, _} = People.create_nomination(tenant, attrs)

      assert {:error, _changeset} = People.create_nomination(tenant, attrs)
    end
  end

  describe "list_nominations_for_round/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      nominator = insert_in_tenant(tenant, :person)
      nominee = insert_in_tenant(tenant, :person)

      {:ok, _} =
        People.create_nomination(tenant, %{
          round_id: round.id,
          nominator_id: nominator.id,
          nominee_id: nominee.id
        })

      %{tenant: tenant, round: round}
    end

    test "returns nominations for the round with preloads", %{tenant: tenant, round: round} do
      result = People.list_nominations_for_round(tenant, round.id)
      assert length(result) == 1
      nomination = hd(result)
      assert nomination.nominator != nil
      assert nomination.nominee != nil
    end

    test "returns empty list for round with no nominations", %{tenant: tenant} do
      campaign = insert_in_tenant(tenant, :campaign)
      empty_round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      assert People.list_nominations_for_round(tenant, empty_round.id) == []
    end
  end

  describe "list_nominations_by_person/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      nominator = insert_in_tenant(tenant, :person)
      nominee1 = insert_in_tenant(tenant, :person)
      nominee2 = insert_in_tenant(tenant, :person)

      {:ok, _} =
        People.create_nomination(tenant, %{
          round_id: round.id,
          nominator_id: nominator.id,
          nominee_id: nominee1.id
        })

      {:ok, _} =
        People.create_nomination(tenant, %{
          round_id: round.id,
          nominator_id: nominator.id,
          nominee_id: nominee2.id
        })

      %{tenant: tenant, round: round, nominator: nominator}
    end

    test "returns nominations by a specific person", %{
      tenant: tenant,
      round: round,
      nominator: nominator
    } do
      result = People.list_nominations_by_person(tenant, round.id, nominator.id)
      assert length(result) == 2
      assert Enum.all?(result, &(&1.nominee != nil))
    end
  end

  describe "count_nominations_per_person/1" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      %{tenant: tenant, round: round}
    end

    test "returns empty map when no nominations", %{tenant: tenant} do
      assert People.count_nominations_per_person(tenant) == %{}
    end

    test "counts nominations per nominee", %{tenant: tenant, round: round} do
      nominee = insert_in_tenant(tenant, :person)
      nominator1 = insert_in_tenant(tenant, :person)
      nominator2 = insert_in_tenant(tenant, :person)

      {:ok, _} =
        People.create_nomination(tenant, %{
          round_id: round.id,
          nominator_id: nominator1.id,
          nominee_id: nominee.id
        })

      {:ok, _} =
        People.create_nomination(tenant, %{
          round_id: round.id,
          nominator_id: nominator2.id,
          nominee_id: nominee.id
        })

      counts = People.count_nominations_per_person(tenant)
      assert counts[nominee.id] == 2
    end
  end

  describe "list_people_with_nomination_counts/1" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      %{tenant: tenant, round: round}
    end

    test "returns people sorted by nomination count descending", %{tenant: tenant, round: round} do
      popular = insert_in_tenant(tenant, :person, %{name: "Popular"})
      unpopular = insert_in_tenant(tenant, :person, %{name: "Unpopular"})
      nominator1 = insert_in_tenant(tenant, :person)
      nominator2 = insert_in_tenant(tenant, :person)

      {:ok, _} =
        People.create_nomination(tenant, %{
          round_id: round.id,
          nominator_id: nominator1.id,
          nominee_id: popular.id
        })

      {:ok, _} =
        People.create_nomination(tenant, %{
          round_id: round.id,
          nominator_id: nominator2.id,
          nominee_id: popular.id
        })

      {:ok, _} =
        People.create_nomination(tenant, %{
          round_id: round.id,
          nominator_id: nominator1.id,
          nominee_id: unpopular.id
        })

      result = People.list_people_with_nomination_counts(tenant)
      assert hd(result).nomination_count == 2
    end
  end

  describe "delete_nominations_by_person/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      nominator = insert_in_tenant(tenant, :person)
      nominee1 = insert_in_tenant(tenant, :person)
      nominee2 = insert_in_tenant(tenant, :person)

      {:ok, _} =
        People.create_nomination(tenant, %{
          round_id: round.id,
          nominator_id: nominator.id,
          nominee_id: nominee1.id
        })

      {:ok, _} =
        People.create_nomination(tenant, %{
          round_id: round.id,
          nominator_id: nominator.id,
          nominee_id: nominee2.id
        })

      %{tenant: tenant, round: round, nominator: nominator}
    end

    test "deletes all nominations by a person in a round", %{
      tenant: tenant,
      round: round,
      nominator: nominator
    } do
      {count, _} = People.delete_nominations_by_person(tenant, round.id, nominator.id)
      assert count == 2
      assert People.list_nominations_by_person(tenant, round.id, nominator.id) == []
    end
  end
end
