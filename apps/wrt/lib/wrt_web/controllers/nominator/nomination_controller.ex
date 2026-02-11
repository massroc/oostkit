defmodule WrtWeb.Nominator.NominationController do
  @moduledoc """
  Handles nomination form display and submission.

  Nominators can:
  - View the nomination form
  - Submit nominations (multiple people with optional reasons)
  - Edit their nominations while the round is still open
  """
  use WrtWeb, :controller

  alias Wrt.People
  alias Wrt.Rounds

  plug WrtWeb.Plugs.TenantPlug
  plug :require_nominator_session

  @doc """
  Shows the nomination form.
  """
  def edit(conn, _params) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org
    person_id = conn.assigns.nominator_person_id
    round_id = conn.assigns.nominator_round_id

    round = Rounds.get_round!(tenant, round_id)
    person = People.get_person!(tenant, person_id)

    # Check if round is still active
    unless Rounds.Round.active?(round) do
      conn
      |> put_flash(:error, "This round has closed. Nominations are no longer being accepted.")
      |> redirect(to: ~p"/org/#{org.slug}/nominate/invalid")
    end

    # Get existing nominations by this person
    existing_nominations = People.list_nominations_by_person(tenant, round_id, person_id)

    render(conn, :edit,
      page_title: "Submit Nominations",
      org: org,
      person: person,
      round: round,
      existing_nominations: existing_nominations
    )
  end

  @doc """
  Submits nominations.
  """
  def submit(conn, %{"nominations" => nominations_params}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org
    person_id = conn.assigns.nominator_person_id
    round_id = conn.assigns.nominator_round_id

    round = Rounds.get_round!(tenant, round_id)

    # Verify round is still active
    unless Rounds.Round.active?(round) do
      conn
      |> put_flash(:error, "This round has closed. Nominations are no longer being accepted.")
      |> redirect(to: ~p"/org/#{org.slug}/nominate/invalid")
    end

    # Delete existing nominations (allows re-submission)
    People.delete_nominations_by_person(tenant, round_id, person_id)

    # Process each nomination
    results =
      nominations_params
      |> Enum.filter(fn {_idx, nom} ->
        # Only process if name and email are present
        nom["name"] != "" and nom["email"] != ""
      end)
      |> Enum.map(fn {_idx, nom} ->
        # Get or create the nominee
        case People.get_or_create_person(tenant, %{
               name: nom["name"],
               email: nom["email"]
             }) do
          {:ok, nominee} ->
            # Create the nomination
            People.create_nomination(tenant, %{
              nominator_id: person_id,
              nominee_id: nominee.id,
              round_id: round_id
            })

          error ->
            error
        end
      end)

    # Check for errors
    errors =
      Enum.filter(results, fn
        {:error, _} -> true
        _ -> false
      end)

    successful =
      Enum.count(results, fn
        {:ok, _} -> true
        _ -> false
      end)

    if Enum.empty?(errors) and successful > 0 do
      conn
      |> put_flash(:info, "Thank you! Your #{successful} nomination(s) have been submitted.")
      |> redirect(to: ~p"/org/#{org.slug}/nominate/form")
    else
      if successful > 0 do
        conn
        |> put_flash(:warning, "#{successful} nomination(s) submitted, but some had errors.")
        |> redirect(to: ~p"/org/#{org.slug}/nominate/form")
      else
        conn
        |> put_flash(:error, "Please add at least one nomination with name and email.")
        |> redirect(to: ~p"/org/#{org.slug}/nominate/form")
      end
    end
  end

  def submit(conn, _params) do
    org = conn.assigns.current_org

    conn
    |> put_flash(:error, "Please add at least one nomination.")
    |> redirect(to: ~p"/org/#{org.slug}/nominate/form")
  end

  # Plug to require nominator session
  defp require_nominator_session(conn, _opts) do
    person_id = get_session(conn, :nominator_person_id)
    round_id = get_session(conn, :nominator_round_id)

    if person_id && round_id do
      conn
      |> assign(:nominator_person_id, person_id)
      |> assign(:nominator_round_id, round_id)
    else
      org = conn.assigns.current_org

      conn
      |> put_flash(:error, "Please use the link from your invitation email to access this page.")
      |> redirect(to: ~p"/org/#{org.slug}/nominate/invalid")
      |> halt()
    end
  end
end
