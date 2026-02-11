defmodule Portal.Marketing do
  @moduledoc """
  Context for marketing features — interest signups and email capture.
  """
  import Ecto.Query
  alias Portal.Repo
  alias Portal.Marketing.InterestSignup

  def create_interest_signup(attrs) do
    %InterestSignup{}
    |> InterestSignup.changeset(attrs)
    |> Repo.insert()
  end

  def change_interest_signup(signup \\ %InterestSignup{}, attrs \\ %{}) do
    InterestSignup.changeset(signup, attrs)
  end

  def list_interest_signups do
    InterestSignup
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def count_interest_signups do
    Repo.aggregate(InterestSignup, :count)
  end
end
