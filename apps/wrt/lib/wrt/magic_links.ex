defmodule Wrt.MagicLinks do
  @moduledoc """
  The MagicLinks context.

  Handles magic link authentication for nominators:
  - Token generation for invitation emails
  - Verification code generation for additional security
  - Token validation and consumption
  """

  import Ecto.Query, warn: false

  alias Wrt.MagicLinks.MagicLink
  alias Wrt.Repo

  @doc """
  Creates a magic link for a person in a round.

  Returns {:ok, magic_link} or {:error, changeset}.
  """
  def create_magic_link(tenant, attrs) do
    %MagicLink{}
    |> MagicLink.changeset(attrs)
    |> Repo.insert(prefix: tenant)
  end

  @doc """
  Gets a magic link by token.

  Returns nil if not found.
  """
  def get_by_token(tenant, token) when is_binary(token) do
    MagicLink
    |> where([m], m.token == ^token)
    |> preload([:person, :round])
    |> Repo.one(prefix: tenant)
  end

  @doc """
  Gets a magic link by ID.
  """
  def get_magic_link(tenant, id) do
    MagicLink
    |> Repo.get(id, prefix: tenant)
    |> Repo.preload([:person, :round], prefix: tenant)
  end

  @doc """
  Gets the active (unused, unexpired) magic link for a person in a round.
  """
  def get_active_link(tenant, person_id, round_id) do
    now = DateTime.utc_now()

    MagicLink
    |> where([m], m.person_id == ^person_id and m.round_id == ^round_id)
    |> where([m], is_nil(m.used_at))
    |> where([m], m.expires_at > ^now)
    |> order_by([m], desc: m.inserted_at)
    |> limit(1)
    |> preload([:person, :round])
    |> Repo.one(prefix: tenant)
  end

  @doc """
  Verifies a magic link token.

  Returns {:ok, magic_link} if valid, {:error, reason} otherwise.
  """
  def verify_token(tenant, token) do
    case get_by_token(tenant, token) do
      nil ->
        {:error, :not_found}

      magic_link ->
        cond do
          MagicLink.used?(magic_link) ->
            {:error, :already_used}

          MagicLink.expired?(magic_link) ->
            {:error, :expired}

          true ->
            {:ok, magic_link}
        end
    end
  end

  @doc """
  Generates a verification code for a magic link.

  This is used for email-based two-factor auth.
  Returns {:ok, magic_link} with the code, or {:error, changeset}.
  """
  def generate_code(tenant, %MagicLink{} = magic_link) do
    magic_link
    |> MagicLink.code_changeset()
    |> Repo.update(prefix: tenant)
  end

  @doc """
  Verifies a code for a magic link.

  Returns {:ok, magic_link} if valid, {:error, reason} otherwise.
  """
  def verify_code(tenant, magic_link_id, code) when is_binary(code) do
    case get_magic_link(tenant, magic_link_id) do
      nil ->
        {:error, :not_found}

      magic_link ->
        cond do
          MagicLink.used?(magic_link) ->
            {:error, :already_used}

          MagicLink.code_expired?(magic_link) ->
            {:error, :code_expired}

          magic_link.code != code ->
            {:error, :invalid_code}

          true ->
            {:ok, magic_link}
        end
    end
  end

  @doc """
  Marks a magic link as used.

  Returns {:ok, magic_link} or {:error, changeset}.
  """
  def use_magic_link(tenant, %MagicLink{} = magic_link) do
    magic_link
    |> MagicLink.use_changeset()
    |> Repo.update(prefix: tenant)
  end

  @doc """
  Creates or gets an active magic link for a person in a round.

  If an active link exists, returns it. Otherwise creates a new one.
  """
  def get_or_create_magic_link(tenant, person_id, round_id) do
    case get_active_link(tenant, person_id, round_id) do
      nil ->
        create_magic_link(tenant, %{person_id: person_id, round_id: round_id})

      magic_link ->
        {:ok, magic_link}
    end
  end

  @doc """
  Deletes expired magic links for cleanup.

  Returns the number of deleted links.
  """
  def delete_expired(tenant) do
    now = DateTime.utc_now()

    {count, _} =
      MagicLink
      |> where([m], m.expires_at < ^now)
      |> Repo.delete_all(prefix: tenant)

    count
  end
end
