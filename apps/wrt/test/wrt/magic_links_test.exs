defmodule Wrt.MagicLinksTest do
  use Wrt.DataCase, async: true

  alias Wrt.MagicLinks
  alias Wrt.MagicLinks.MagicLink

  describe "create_magic_link/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      %{tenant: tenant, round: round, person: person}
    end

    test "creates a magic link with generated token", %{tenant: tenant, round: round, person: person} do
      attrs = %{person_id: person.id, round_id: round.id}

      assert {:ok, magic_link} = MagicLinks.create_magic_link(tenant, attrs)
      assert magic_link.person_id == person.id
      assert magic_link.round_id == round.id
      assert magic_link.token != nil
      assert byte_size(magic_link.token) > 20
      assert magic_link.expires_at != nil
      assert is_nil(magic_link.used_at)
    end

    test "sets expiration to 24 hours from now", %{tenant: tenant, round: round, person: person} do
      attrs = %{person_id: person.id, round_id: round.id}

      {:ok, magic_link} = MagicLinks.create_magic_link(tenant, attrs)

      now = DateTime.utc_now()
      diff_seconds = DateTime.diff(magic_link.expires_at, now)

      # Should expire in approximately 24 hours (allow 10 second tolerance)
      assert diff_seconds >= 24 * 60 * 60 - 10
      assert diff_seconds <= 24 * 60 * 60 + 10
    end

    test "returns error when person_id is missing", %{tenant: tenant, round: round} do
      attrs = %{round_id: round.id}

      assert {:error, changeset} = MagicLinks.create_magic_link(tenant, attrs)
      assert "can't be blank" in errors_on(changeset).person_id
    end

    test "returns error when round_id is missing", %{tenant: tenant, person: person} do
      attrs = %{person_id: person.id}

      assert {:error, changeset} = MagicLinks.create_magic_link(tenant, attrs)
      assert "can't be blank" in errors_on(changeset).round_id
    end
  end

  describe "get_by_token/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      {:ok, magic_link} =
        MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})

      %{tenant: tenant, magic_link: magic_link, person: person, round: round}
    end

    test "returns the magic link when token is valid", %{tenant: tenant, magic_link: magic_link} do
      result = MagicLinks.get_by_token(tenant, magic_link.token)

      assert result.id == magic_link.id
      assert result.token == magic_link.token
    end

    test "preloads person and round", %{tenant: tenant, magic_link: magic_link, person: person, round: round} do
      result = MagicLinks.get_by_token(tenant, magic_link.token)

      assert result.person.id == person.id
      assert result.round.id == round.id
    end

    test "returns nil for non-existent token", %{tenant: tenant} do
      assert is_nil(MagicLinks.get_by_token(tenant, "nonexistent-token"))
    end
  end

  describe "verify_token/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      {:ok, magic_link} =
        MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})

      %{tenant: tenant, magic_link: magic_link}
    end

    test "returns {:ok, magic_link} for valid token", %{tenant: tenant, magic_link: magic_link} do
      assert {:ok, result} = MagicLinks.verify_token(tenant, magic_link.token)
      assert result.id == magic_link.id
    end

    test "returns {:error, :not_found} for non-existent token", %{tenant: tenant} do
      assert {:error, :not_found} = MagicLinks.verify_token(tenant, "bad-token")
    end

    test "returns {:error, :already_used} for used token", %{tenant: tenant, magic_link: magic_link} do
      {:ok, _} = MagicLinks.use_magic_link(tenant, magic_link)

      assert {:error, :already_used} = MagicLinks.verify_token(tenant, magic_link.token)
    end

    test "returns {:error, :expired} for expired token", %{tenant: tenant} do
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 2})
      person = insert_in_tenant(tenant, :person)

      # Create an expired magic link directly in the database
      expired_link = %MagicLink{
        token: "expired-token-#{System.unique_integer([:positive])}",
        expires_at: DateTime.utc_now() |> DateTime.add(-1 * 60 * 60) |> DateTime.truncate(:second),
        person_id: person.id,
        round_id: round.id
      }

      {:ok, expired} = Wrt.Repo.insert(expired_link, prefix: tenant)

      assert {:error, :expired} = MagicLinks.verify_token(tenant, expired.token)
    end
  end

  describe "generate_code/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      {:ok, magic_link} =
        MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})

      %{tenant: tenant, magic_link: magic_link}
    end

    test "generates a 6-digit code", %{tenant: tenant, magic_link: magic_link} do
      {:ok, updated} = MagicLinks.generate_code(tenant, magic_link)

      assert updated.code != nil
      assert String.length(updated.code) == 6
      assert String.match?(updated.code, ~r/^\d{6}$/)
    end

    test "sets code expiration to 15 minutes", %{tenant: tenant, magic_link: magic_link} do
      {:ok, updated} = MagicLinks.generate_code(tenant, magic_link)

      now = DateTime.utc_now()
      diff_seconds = DateTime.diff(updated.code_expires_at, now)

      # Should expire in approximately 15 minutes (allow 10 second tolerance)
      assert diff_seconds >= 15 * 60 - 10
      assert diff_seconds <= 15 * 60 + 10
    end
  end

  describe "verify_code/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      {:ok, magic_link} =
        MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})

      {:ok, magic_link} = MagicLinks.generate_code(tenant, magic_link)

      %{tenant: tenant, magic_link: magic_link}
    end

    test "returns {:ok, magic_link} for valid code", %{tenant: tenant, magic_link: magic_link} do
      assert {:ok, result} = MagicLinks.verify_code(tenant, magic_link.id, magic_link.code)
      assert result.id == magic_link.id
    end

    test "returns {:error, :not_found} for non-existent magic link", %{tenant: tenant, magic_link: magic_link} do
      assert {:error, :not_found} = MagicLinks.verify_code(tenant, -1, magic_link.code)
    end

    test "returns {:error, :invalid_code} for wrong code", %{tenant: tenant, magic_link: magic_link} do
      assert {:error, :invalid_code} = MagicLinks.verify_code(tenant, magic_link.id, "000000")
    end

    test "returns {:error, :already_used} for used magic link", %{tenant: tenant, magic_link: magic_link} do
      {:ok, _} = MagicLinks.use_magic_link(tenant, magic_link)

      assert {:error, :already_used} = MagicLinks.verify_code(tenant, magic_link.id, magic_link.code)
    end

    test "returns {:error, :code_expired} for expired code", %{tenant: tenant} do
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 2})
      person = insert_in_tenant(tenant, :person)

      # Create a magic link with an expired code directly
      expired_code_link = %MagicLink{
        token: "token-#{System.unique_integer([:positive])}",
        expires_at: DateTime.utc_now() |> DateTime.add(24 * 60 * 60) |> DateTime.truncate(:second),
        code: "123456",
        code_expires_at: DateTime.utc_now() |> DateTime.add(-5 * 60) |> DateTime.truncate(:second),
        person_id: person.id,
        round_id: round.id
      }

      {:ok, link} = Wrt.Repo.insert(expired_code_link, prefix: tenant)

      assert {:error, :code_expired} = MagicLinks.verify_code(tenant, link.id, "123456")
    end
  end

  describe "use_magic_link/2" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      {:ok, magic_link} =
        MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})

      %{tenant: tenant, magic_link: magic_link}
    end

    test "marks the magic link as used", %{tenant: tenant, magic_link: magic_link} do
      assert is_nil(magic_link.used_at)

      {:ok, used} = MagicLinks.use_magic_link(tenant, magic_link)

      assert used.used_at != nil
      assert MagicLink.used?(used)
    end
  end

  describe "get_or_create_magic_link/3" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      %{tenant: tenant, round: round, person: person}
    end

    test "creates a new magic link when none exists", %{tenant: tenant, round: round, person: person} do
      assert {:ok, magic_link} = MagicLinks.get_or_create_magic_link(tenant, person.id, round.id)

      assert magic_link.person_id == person.id
      assert magic_link.round_id == round.id
    end

    test "returns existing active link if one exists", %{tenant: tenant, round: round, person: person} do
      {:ok, original} = MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})
      {:ok, retrieved} = MagicLinks.get_or_create_magic_link(tenant, person.id, round.id)

      assert retrieved.id == original.id
      assert retrieved.token == original.token
    end

    test "creates new link if existing one is expired", %{tenant: tenant, round: round, person: person} do
      # Create an expired link
      expired_link = %MagicLink{
        token: "expired-#{System.unique_integer([:positive])}",
        expires_at: DateTime.utc_now() |> DateTime.add(-1 * 60 * 60) |> DateTime.truncate(:second),
        person_id: person.id,
        round_id: round.id
      }

      {:ok, expired} = Wrt.Repo.insert(expired_link, prefix: tenant)

      {:ok, new_link} = MagicLinks.get_or_create_magic_link(tenant, person.id, round.id)

      assert new_link.id != expired.id
      assert new_link.token != expired.token
    end

    test "creates new link if existing one is used", %{tenant: tenant, round: round, person: person} do
      {:ok, original} = MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})
      {:ok, _used} = MagicLinks.use_magic_link(tenant, original)

      {:ok, new_link} = MagicLinks.get_or_create_magic_link(tenant, person.id, round.id)

      assert new_link.id != original.id
    end
  end

  describe "delete_expired/1" do
    setup do
      tenant = create_test_tenant()
      campaign = insert_in_tenant(tenant, :campaign)
      round = insert_in_tenant(tenant, :round, %{campaign_id: campaign.id, round_number: 1})
      person = insert_in_tenant(tenant, :person)

      %{tenant: tenant, round: round, person: person}
    end

    test "deletes expired magic links", %{tenant: tenant, round: round, person: person} do
      # Create expired links
      for i <- 1..3 do
        expired = %MagicLink{
          token: "expired-#{i}-#{System.unique_integer([:positive])}",
          expires_at: DateTime.utc_now() |> DateTime.add(-i * 60 * 60) |> DateTime.truncate(:second),
          person_id: person.id,
          round_id: round.id
        }

        Wrt.Repo.insert!(expired, prefix: tenant)
      end

      # Create a valid link
      {:ok, valid} = MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})

      deleted_count = MagicLinks.delete_expired(tenant)

      assert deleted_count == 3

      # Valid link should still exist
      assert MagicLinks.get_by_token(tenant, valid.token) != nil
    end

    test "returns 0 when no expired links exist", %{tenant: tenant, round: round, person: person} do
      {:ok, _valid} = MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})

      assert MagicLinks.delete_expired(tenant) == 0
    end
  end

  describe "MagicLink schema helpers" do
    test "expired?/1 returns true when expires_at is in the past" do
      expired = %MagicLink{expires_at: DateTime.utc_now() |> DateTime.add(-60)}
      assert MagicLink.expired?(expired)
    end

    test "expired?/1 returns false when expires_at is in the future" do
      valid = %MagicLink{expires_at: DateTime.utc_now() |> DateTime.add(60)}
      refute MagicLink.expired?(valid)
    end

    test "used?/1 returns true when used_at is set" do
      used = %MagicLink{used_at: DateTime.utc_now()}
      assert MagicLink.used?(used)
    end

    test "used?/1 returns false when used_at is nil" do
      unused = %MagicLink{used_at: nil}
      refute MagicLink.used?(unused)
    end

    test "code_expired?/1 returns true when code_expires_at is nil" do
      no_code = %MagicLink{code_expires_at: nil}
      assert MagicLink.code_expired?(no_code)
    end

    test "code_expired?/1 returns true when code_expires_at is in the past" do
      expired = %MagicLink{code_expires_at: DateTime.utc_now() |> DateTime.add(-60)}
      assert MagicLink.code_expired?(expired)
    end

    test "code_expired?/1 returns false when code_expires_at is in the future" do
      valid = %MagicLink{code_expires_at: DateTime.utc_now() |> DateTime.add(60)}
      refute MagicLink.code_expired?(valid)
    end

    test "valid?/1 returns true when not expired and not used" do
      valid = %MagicLink{
        expires_at: DateTime.utc_now() |> DateTime.add(60),
        used_at: nil
      }

      assert MagicLink.valid?(valid)
    end

    test "valid?/1 returns false when expired" do
      expired = %MagicLink{
        expires_at: DateTime.utc_now() |> DateTime.add(-60),
        used_at: nil
      }

      refute MagicLink.valid?(expired)
    end

    test "valid?/1 returns false when used" do
      used = %MagicLink{
        expires_at: DateTime.utc_now() |> DateTime.add(60),
        used_at: DateTime.utc_now()
      }

      refute MagicLink.valid?(used)
    end
  end
end
