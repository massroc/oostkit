defmodule Wrt.Factory do
  @moduledoc """
  ExMachina factory for generating test data.
  """

  use ExMachina.Ecto, repo: Wrt.Repo

  alias Wrt.Campaigns.Campaign
  alias Wrt.Rounds.{Round, Contact}
  alias Wrt.People.{Person, Nomination}
  alias Wrt.MagicLinks.MagicLink

  # ============================================================================
  # Campaign Factory
  # ============================================================================

  def campaign_factory do
    %Campaign{
      name: sequence(:campaign_name, &"Test Campaign #{&1}"),
      description: "A test campaign for referral process",
      status: "draft",
      default_round_duration_days: 7,
      target_participant_count: 20
    }
  end

  def active_campaign_factory do
    struct!(
      campaign_factory(),
      status: "active",
      started_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  def completed_campaign_factory do
    struct!(
      campaign_factory(),
      status: "completed",
      started_at:
        DateTime.utc_now() |> DateTime.add(-7 * 24 * 60 * 60) |> DateTime.truncate(:second),
      completed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  # ============================================================================
  # Round Factory
  # ============================================================================

  def round_factory do
    %Round{
      round_number: sequence(:round_number, & &1),
      status: "pending",
      reminder_enabled: false,
      reminder_days: 2
    }
  end

  def active_round_factory do
    struct!(
      round_factory(),
      status: "active",
      deadline:
        DateTime.utc_now() |> DateTime.add(7 * 24 * 60 * 60) |> DateTime.truncate(:second),
      started_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  def closed_round_factory do
    struct!(
      round_factory(),
      status: "closed",
      deadline:
        DateTime.utc_now() |> DateTime.add(-1 * 24 * 60 * 60) |> DateTime.truncate(:second),
      started_at:
        DateTime.utc_now() |> DateTime.add(-8 * 24 * 60 * 60) |> DateTime.truncate(:second),
      closed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  # ============================================================================
  # Person Factory
  # ============================================================================

  def person_factory do
    %Person{
      name: Faker.Person.name(),
      email: sequence(:email, &"person#{&1}@example.com"),
      source: "nominated"
    }
  end

  def seed_person_factory do
    struct!(
      person_factory(),
      source: "seed"
    )
  end

  # ============================================================================
  # Contact Factory
  # ============================================================================

  def contact_factory do
    %Contact{
      email_status: "pending"
    }
  end

  def invited_contact_factory do
    struct!(
      contact_factory(),
      email_status: "sent",
      invited_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  def responded_contact_factory do
    struct!(
      contact_factory(),
      email_status: "clicked",
      invited_at:
        DateTime.utc_now() |> DateTime.add(-2 * 24 * 60 * 60) |> DateTime.truncate(:second),
      delivered_at:
        DateTime.utc_now() |> DateTime.add(-2 * 24 * 60 * 60) |> DateTime.truncate(:second),
      opened_at:
        DateTime.utc_now() |> DateTime.add(-1 * 24 * 60 * 60) |> DateTime.truncate(:second),
      clicked_at:
        DateTime.utc_now() |> DateTime.add(-1 * 24 * 60 * 60) |> DateTime.truncate(:second),
      responded_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  # ============================================================================
  # Nomination Factory
  # ============================================================================

  def nomination_factory do
    %Nomination{}
  end

  # ============================================================================
  # MagicLink Factory
  # ============================================================================

  def magic_link_factory do
    %MagicLink{
      token: generate_token(),
      expires_at: DateTime.utc_now() |> DateTime.add(24 * 60 * 60) |> DateTime.truncate(:second)
    }
  end

  def expired_magic_link_factory do
    struct!(
      magic_link_factory(),
      expires_at: DateTime.utc_now() |> DateTime.add(-1 * 60 * 60) |> DateTime.truncate(:second)
    )
  end

  def used_magic_link_factory do
    struct!(
      magic_link_factory(),
      used_at: DateTime.utc_now() |> DateTime.truncate(:second)
    )
  end

  def magic_link_with_code_factory do
    struct!(
      magic_link_factory(),
      code: generate_code(),
      code_expires_at: DateTime.utc_now() |> DateTime.add(15 * 60) |> DateTime.truncate(:second)
    )
  end

  def magic_link_with_expired_code_factory do
    struct!(
      magic_link_factory(),
      code: generate_code(),
      code_expires_at: DateTime.utc_now() |> DateTime.add(-5 * 60) |> DateTime.truncate(:second)
    )
  end

  # ============================================================================
  # Private Helpers
  # ============================================================================

  defp generate_token do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
  end

  defp generate_code do
    :crypto.strong_rand_bytes(4)
    |> :binary.decode_unsigned()
    |> rem(1_000_000)
    |> Integer.to_string()
    |> String.pad_leading(6, "0")
  end
end
