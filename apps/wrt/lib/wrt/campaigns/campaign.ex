defmodule Wrt.Campaigns.Campaign do
  @moduledoc """
  Schema for referral campaigns.

  A campaign represents a single referral process for selecting workshop participants.
  Each organisation can have one active campaign at a time.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft active completed)

  schema "campaigns" do
    field :name, :string
    field :description, :string
    field :status, :string, default: "draft"
    field :default_round_duration_days, :integer, default: 7
    field :target_participant_count, :integer

    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new campaign.
  """
  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :description, :default_round_duration_days, :target_participant_count])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_number(:default_round_duration_days, greater_than: 0, less_than_or_equal_to: 30)
    |> validate_number(:target_participant_count, greater_than: 0, less_than_or_equal_to: 100)
  end

  @doc """
  Changeset for updating campaign details.
  """
  def update_changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :description, :default_round_duration_days, :target_participant_count])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_number(:default_round_duration_days, greater_than: 0, less_than_or_equal_to: 30)
    |> validate_number(:target_participant_count, greater_than: 0, less_than_or_equal_to: 100)
  end

  @doc """
  Changeset for starting a campaign.
  """
  def start_changeset(campaign) do
    campaign
    |> change()
    |> put_change(:status, "active")
    |> put_change(:started_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset for completing a campaign.
  """
  def complete_changeset(campaign) do
    campaign
    |> change()
    |> put_change(:status, "completed")
    |> put_change(:completed_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Returns valid status values.
  """
  def statuses, do: @statuses

  @doc """
  Checks if the campaign is in draft status.
  """
  def draft?(%__MODULE__{status: "draft"}), do: true
  def draft?(_), do: false

  @doc """
  Checks if the campaign is active.
  """
  def active?(%__MODULE__{status: "active"}), do: true
  def active?(_), do: false

  @doc """
  Checks if the campaign is completed.
  """
  def completed?(%__MODULE__{status: "completed"}), do: true
  def completed?(_), do: false
end
