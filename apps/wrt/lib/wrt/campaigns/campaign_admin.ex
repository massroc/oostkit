defmodule Wrt.Campaigns.CampaignAdmin do
  @moduledoc """
  Schema for campaign administrators.

  Campaign admins are invited collaborators who can help manage a specific campaign.
  They have limited permissions compared to org admins.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Wrt.Auth.Password

  alias Wrt.Campaigns.Campaign
  alias Wrt.Orgs.OrgAdmin

  schema "campaign_admins" do
    field :name, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true

    belongs_to :campaign, Campaign
    belongs_to :invited_by, OrgAdmin

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for inviting a new campaign admin.
  """
  def changeset(campaign_admin, attrs) do
    campaign_admin
    |> cast(attrs, [:name, :email, :password, :campaign_id, :invited_by_id])
    |> validate_required([:name, :email, :password, :campaign_id])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
    |> unique_constraint([:campaign_id, :email])
    |> foreign_key_constraint(:campaign_id)
    |> foreign_key_constraint(:invited_by_id)
    |> hash_password()
  end

  @doc """
  Changeset for updating campaign admin details.
  """
  def update_changeset(campaign_admin, attrs) do
    campaign_admin
    |> cast(attrs, [:name, :email])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> unique_constraint([:campaign_id, :email])
  end

  defdelegate valid_password?(admin, password), to: Wrt.Auth.Password
end
