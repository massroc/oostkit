defmodule Portal.MarketingTest do
  use Portal.DataCase, async: true

  alias Portal.Marketing

  describe "create_interest_signup/1" do
    test "creates a signup with valid attrs" do
      assert {:ok, signup} =
               Marketing.create_interest_signup(%{
                 name: "Jane",
                 email: "jane@example.com",
                 context: "signup"
               })

      assert signup.name == "Jane"
      assert signup.email == "jane@example.com"
      assert signup.context == "signup"
    end

    test "creates a signup with email only" do
      assert {:ok, signup} = Marketing.create_interest_signup(%{email: "test@example.com"})
      assert signup.email == "test@example.com"
      assert signup.name == nil
    end

    test "fails without email" do
      assert {:error, changeset} = Marketing.create_interest_signup(%{name: "Jane"})
      assert errors_on(changeset).email
    end

    test "fails with invalid email" do
      assert {:error, changeset} = Marketing.create_interest_signup(%{email: "not-an-email"})
      assert errors_on(changeset).email
    end

    test "fails with duplicate email" do
      Marketing.create_interest_signup(%{email: "dupe@example.com"})
      assert {:error, changeset} = Marketing.create_interest_signup(%{email: "dupe@example.com"})
      assert "has already been registered" in errors_on(changeset).email
    end
  end

  describe "list_interest_signups/0" do
    test "returns all signups" do
      {:ok, _} = Marketing.create_interest_signup(%{email: "first@example.com"})
      {:ok, _} = Marketing.create_interest_signup(%{email: "second@example.com"})

      signups = Marketing.list_interest_signups()
      assert length(signups) == 2
      emails = Enum.map(signups, & &1.email)
      assert "first@example.com" in emails
      assert "second@example.com" in emails
    end
  end

  describe "count_interest_signups/0" do
    test "returns count of signups" do
      assert Marketing.count_interest_signups() == 0

      Marketing.create_interest_signup(%{email: "one@example.com"})
      Marketing.create_interest_signup(%{email: "two@example.com"})

      assert Marketing.count_interest_signups() == 2
    end
  end

  describe "get_interest_signup!/1" do
    test "returns signup by id" do
      {:ok, signup} = Marketing.create_interest_signup(%{email: "get@example.com"})
      assert Marketing.get_interest_signup!(signup.id).email == "get@example.com"
    end

    test "raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Marketing.get_interest_signup!(0)
      end
    end
  end

  describe "delete_interest_signup/1" do
    test "deletes a signup" do
      {:ok, signup} = Marketing.create_interest_signup(%{email: "delete@example.com"})
      assert {:ok, _} = Marketing.delete_interest_signup(signup)
      assert Marketing.count_interest_signups() == 0
    end
  end

  describe "search_interest_signups/1" do
    test "searches by email" do
      Marketing.create_interest_signup(%{email: "alice@example.com", name: "Alice"})
      Marketing.create_interest_signup(%{email: "bob@example.com", name: "Bob"})

      results = Marketing.search_interest_signups("alice")
      assert length(results) == 1
      assert hd(results).email == "alice@example.com"
    end

    test "searches by name" do
      Marketing.create_interest_signup(%{email: "a@example.com", name: "Alice"})
      Marketing.create_interest_signup(%{email: "b@example.com", name: "Bob"})

      results = Marketing.search_interest_signups("Bob")
      assert length(results) == 1
      assert hd(results).name == "Bob"
    end

    test "searches by context" do
      Marketing.create_interest_signup(%{email: "a@example.com", context: "signup"})
      Marketing.create_interest_signup(%{email: "b@example.com", context: "tool:wrt"})

      results = Marketing.search_interest_signups("tool:wrt")
      assert length(results) == 1
      assert hd(results).context == "tool:wrt"
    end

    test "returns empty list for no matches" do
      Marketing.create_interest_signup(%{email: "a@example.com"})
      assert Marketing.search_interest_signups("zzz") == []
    end
  end
end
