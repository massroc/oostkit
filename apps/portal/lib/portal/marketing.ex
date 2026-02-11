defmodule Portal.Marketing do
  @moduledoc """
  Context for marketing features — interest signups and email capture.
  """
  import Ecto.Query
  alias Portal.Marketing.InterestSignup
  alias Portal.Repo

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

  def get_interest_signup!(id) do
    Repo.get!(InterestSignup, id)
  end

  def delete_interest_signup(%InterestSignup{} = signup) do
    Repo.delete(signup)
  end

  def search_interest_signups(query) do
    search = "%#{query}%"

    InterestSignup
    |> where([s], ilike(s.email, ^search) or ilike(s.name, ^search) or ilike(s.context, ^search))
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end
end
