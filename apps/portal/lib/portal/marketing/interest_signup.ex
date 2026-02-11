defmodule Portal.Marketing.InterestSignup do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "interest_signups" do
    field :name, :string
    field :email, :string
    field :context, :string

    timestamps(updated_at: false)
  end

  def changeset(signup, attrs) do
    signup
    |> cast(attrs, [:name, :email, :context])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
    |> validate_length(:email, max: 160)
    |> validate_length(:name, max: 160)
    |> unique_constraint(:email, message: "has already been registered")
  end
end
