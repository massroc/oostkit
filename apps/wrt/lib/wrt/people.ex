defmodule Wrt.People do
  @moduledoc """
  The People context.

  Handles people and nominations within a tenant, including:
  - Seed group management
  - CSV parsing for bulk imports
  - Nomination tracking
  - Convergence counting
  """

  import Ecto.Query, warn: false

  alias Wrt.People.{Nomination, Person}
  alias Wrt.Repo

  NimbleCSV.define(CsvParser, separator: ",", escape: "\"")

  # =============================================================================
  # Person Functions
  # =============================================================================

  @doc """
  Lists all people for a tenant.
  """
  def list_people(tenant) do
    Person
    |> order_by([p], asc: p.name)
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Lists seed group people.
  """
  def list_seed_people(tenant) do
    Person
    |> where([p], p.source == "seed")
    |> order_by([p], asc: p.name)
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Lists nominated people (not in seed group).
  """
  def list_nominated_people(tenant) do
    Person
    |> where([p], p.source == "nominated")
    |> order_by([p], asc: p.name)
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Gets a person by ID, raising if not found.
  """
  def get_person!(tenant, id) do
    Repo.get!(Person, id, prefix: tenant)
  end

  @doc """
  Gets a person by email.
  """
  def get_person_by_email(tenant, email) when is_binary(email) do
    Person
    |> where([p], p.email == ^String.downcase(email))
    |> Repo.one(prefix: tenant)
  end

  @doc """
  Creates a seed person.
  """
  def create_seed_person(tenant, attrs) do
    %Person{}
    |> Person.seed_changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Creates a nominated person.
  """
  def create_nominated_person(tenant, attrs) do
    %Person{}
    |> Person.nominated_changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Gets or creates a person by email.

  If the person exists, returns them. Otherwise creates as nominated.
  """
  def get_or_create_person(tenant, attrs) do
    email = attrs[:email] || attrs["email"]

    case get_person_by_email(tenant, email) do
      nil -> create_nominated_person(tenant, attrs)
      person -> {:ok, person}
    end
  end

  @doc """
  Deletes a person.
  """
  def delete_person(tenant, %Person{} = person) do
    Repo.delete(person, prefix: tenant)
  end

  @doc """
  Counts people by source.
  """
  def count_people_by_source(tenant) do
    Person
    |> group_by([p], p.source)
    |> select([p], {p.source, count(p.id)})
    |> Repo.all(prefix: tenant)
    |> Map.new()
  end

  # =============================================================================
  # Seed Group CSV Import
  # =============================================================================

  @doc """
  Parses a CSV file and returns a list of people to import.

  Expected columns: name, email (case-insensitive headers)
  Returns {:ok, people} or {:error, reason}
  """
  def parse_seed_csv(csv_content) do
    [headers | rows] = CsvParser.parse_string(csv_content, skip_headers: false)

    # Normalize headers to lowercase
    headers = Enum.map(headers, &String.downcase(String.trim(&1)))

    # Find column indices
    name_idx = Enum.find_index(headers, &(&1 in ["name", "full name", "fullname"]))
    email_idx = Enum.find_index(headers, &(&1 in ["email", "email address", "e-mail"]))

    cond do
      is_nil(name_idx) ->
        {:error, "CSV must have a 'name' column"}

      is_nil(email_idx) ->
        {:error, "CSV must have an 'email' column"}

      true ->
        people =
          rows
          |> Enum.with_index(2)
          |> Enum.map(fn {row, line_num} ->
            name = Enum.at(row, name_idx, "") |> String.trim()
            email = Enum.at(row, email_idx, "") |> String.trim()

            %{
              name: name,
              email: email,
              line: line_num,
              valid: name != "" && email != "" && valid_email?(email)
            }
          end)

        {:ok, people}
    end
  rescue
    e -> {:error, "Failed to parse CSV: #{Exception.message(e)}"}
  end

  @doc """
  Imports seed people from parsed CSV data.

  Returns {:ok, %{imported: count, skipped: count, errors: [...]}}
  """
  def import_seed_people(tenant, parsed_people) do
    results =
      Enum.reduce(parsed_people, %{imported: 0, skipped: 0, errors: []}, fn person, acc ->
        import_single_person(tenant, person, acc)
      end)

    {:ok, %{results | errors: Enum.reverse(results.errors)}}
  end

  defp import_single_person(_tenant, %{valid: false, line: line}, acc) do
    error = "Line #{line}: Invalid or missing data"
    %{acc | errors: [error | acc.errors]}
  end

  defp import_single_person(tenant, person, acc) do
    case create_seed_person(tenant, %{name: person.name, email: person.email}) do
      {:ok, _} ->
        %{acc | imported: acc.imported + 1}

      {:error, changeset} ->
        handle_import_error(changeset, person.line, acc)
    end
  end

  defp handle_import_error(changeset, line, acc) do
    if duplicate_email_error?(changeset) do
      %{acc | skipped: acc.skipped + 1}
    else
      error = "Line #{line}: #{format_changeset_errors(changeset)}"
      %{acc | errors: [error | acc.errors]}
    end
  end

  defp valid_email?(email) do
    String.match?(email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
  end

  defp duplicate_email_error?(changeset) do
    Enum.any?(changeset.errors, fn
      {:email, {_, [constraint: :unique, constraint_name: _]}} -> true
      _ -> false
    end)
  end

  defp format_changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map_join("; ", fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
  end

  # =============================================================================
  # Nomination Functions
  # =============================================================================

  @doc """
  Creates a nomination.
  """
  def create_nomination(tenant, attrs) do
    %Nomination{}
    |> Nomination.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Lists nominations for a round.
  """
  def list_nominations_for_round(tenant, round_id) do
    Nomination
    |> where([n], n.round_id == ^round_id)
    |> preload([:nominator, :nominee])
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Lists nominations made by a person in a round.
  """
  def list_nominations_by_person(tenant, round_id, person_id) do
    Nomination
    |> where([n], n.round_id == ^round_id and n.nominator_id == ^person_id)
    |> preload([:nominee])
    |> Repo.all(prefix: tenant)
  end

  @doc """
  Counts nominations for each person (convergence).

  Returns a map of person_id => nomination_count.
  """
  def count_nominations_per_person(tenant) do
    Nomination
    |> group_by([n], n.nominee_id)
    |> select([n], {n.nominee_id, count(n.id)})
    |> Repo.all(prefix: tenant)
    |> Map.new()
  end

  @doc """
  Lists people with their nomination counts, sorted by count descending.
  """
  def list_people_with_nomination_counts(tenant) do
    counts = count_nominations_per_person(tenant)

    list_people(tenant)
    |> Enum.map(fn person ->
      Map.put(person, :nomination_count, Map.get(counts, person.id, 0))
    end)
    |> Enum.sort_by(& &1.nomination_count, :desc)
  end

  @doc """
  Deletes all nominations by a person in a round.

  Used when a nominator wants to re-submit their nominations.
  """
  def delete_nominations_by_person(tenant, round_id, person_id) do
    Nomination
    |> where([n], n.round_id == ^round_id and n.nominator_id == ^person_id)
    |> Repo.delete_all(prefix: tenant)
  end
end
