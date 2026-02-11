defmodule Portal.Accounts.UserToolInterest do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "user_tool_interests" do
    field :tool_id, :string
    belongs_to :user, Portal.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(interest, attrs) do
    interest
    |> cast(attrs, [:user_id, :tool_id])
    |> validate_required([:user_id, :tool_id])
    |> unique_constraint([:user_id, :tool_id])
  end
end
