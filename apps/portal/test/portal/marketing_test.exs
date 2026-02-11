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
end
