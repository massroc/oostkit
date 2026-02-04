defmodule Wrt.Rounds.Round do
  @moduledoc """
  Schema for referral rounds.

  A round represents one phase of the referral process where
  invitations are sent and nominations are collected.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Wrt.Campaigns.Campaign

  @statuses ~w(pending active closed)

  schema "rounds" do
    field :round_number, :integer
    field :status, :string, default: "pending"
    field :deadline, :utc_datetime
    field :reminder_enabled, :boolean, default: false
    field :reminder_days, :integer, default: 2

    field :started_at, :utc_datetime
    field :closed_at, :utc_datetime

    belongs_to :campaign, Campaign

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a round.
  """
  def changeset(round, attrs) do
    round
    |> cast(attrs, [:campaign_id, :round_number, :deadline, :reminder_enabled, :reminder_days])
    |> validate_required([:campaign_id, :round_number])
    |> validate_number(:round_number, greater_than: 0)
    |> validate_number(:reminder_days, greater_than: 0, less_than_or_equal_to: 7)
    |> foreign_key_constraint(:campaign_id)
    |> unique_constraint([:campaign_id, :round_number])
  end

  @doc """
  Changeset for starting a round.
  """
  def start_changeset(round, deadline) do
    round
    |> change()
    |> put_change(:status, "active")
    |> put_change(:deadline, deadline)
    |> put_change(:started_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset for closing a round.
  """
  def close_changeset(round) do
    round
    |> change()
    |> put_change(:status, "closed")
    |> put_change(:closed_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Changeset for extending a round deadline.
  """
  def extend_changeset(round, new_deadline) do
    round
    |> change()
    |> put_change(:deadline, new_deadline)
  end

  @doc """
  Returns valid status values.
  """
  def statuses, do: @statuses

  @doc """
  Checks if the round is pending.
  """
  def pending?(%__MODULE__{status: "pending"}), do: true
  def pending?(_), do: false

  @doc """
  Checks if the round is active.
  """
  def active?(%__MODULE__{status: "active"}), do: true
  def active?(_), do: false

  @doc """
  Checks if the round is closed.
  """
  def closed?(%__MODULE__{status: "closed"}), do: true
  def closed?(_), do: false

  @doc """
  Checks if the round has passed its deadline.
  """
  def past_deadline?(%__MODULE__{deadline: nil}), do: false

  def past_deadline?(%__MODULE__{deadline: deadline}) do
    DateTime.compare(DateTime.utc_now(), deadline) == :gt
  end
end
