defmodule Wrt.Reports do
  @moduledoc """
  The Reports context.

  Provides aggregated statistics and reporting functions for campaigns:
  - Campaign-level statistics
  - Round-level statistics
  - Convergence metrics
  - Response tracking
  """

  import Ecto.Query, warn: false
  alias Wrt.Repo
  alias Wrt.Rounds.{Round, Contact}
  alias Wrt.People.{Person, Nomination}

  # =============================================================================
  # Campaign Statistics
  # =============================================================================

  @doc """
  Gets comprehensive statistics for a campaign.
  """
  def get_campaign_stats(tenant, campaign_id) do
    %{
      rounds: get_rounds_summary(tenant, campaign_id),
      contacts: get_contacts_summary(tenant, campaign_id),
      nominations: get_nominations_summary(tenant, campaign_id),
      convergence: get_convergence_stats(tenant)
    }
  end

  @doc """
  Gets a summary of rounds for a campaign.
  """
  def get_rounds_summary(tenant, campaign_id) do
    rounds =
      Round
      |> where([r], r.campaign_id == ^campaign_id)
      |> Repo.all(prefix: tenant)

    %{
      total: length(rounds),
      active: Enum.count(rounds, &(&1.status == "active")),
      closed: Enum.count(rounds, &(&1.status == "closed")),
      pending: Enum.count(rounds, &(&1.status == "pending"))
    }
  end

  @doc """
  Gets a summary of contacts across all rounds of a campaign.
  """
  def get_contacts_summary(tenant, campaign_id) do
    query =
      from c in Contact,
        join: r in Round,
        on: c.round_id == r.id,
        where: r.campaign_id == ^campaign_id,
        select: %{
          total: count(c.id),
          invited: count(c.invited_at),
          delivered: count(c.delivered_at),
          opened: count(c.opened_at),
          clicked: count(c.clicked_at),
          responded: count(c.responded_at)
        }

    case Repo.one(query, prefix: tenant) do
      nil ->
        %{total: 0, invited: 0, delivered: 0, opened: 0, clicked: 0, responded: 0}

      stats ->
        response_rate =
          if stats.total > 0,
            do: Float.round(stats.responded / stats.total * 100, 1),
            else: 0.0

        open_rate =
          if stats.delivered > 0,
            do: Float.round(stats.opened / stats.delivered * 100, 1),
            else: 0.0

        Map.merge(stats, %{response_rate: response_rate, open_rate: open_rate})
    end
  end

  @doc """
  Gets a summary of nominations for a campaign.
  """
  def get_nominations_summary(tenant, campaign_id) do
    query =
      from n in Nomination,
        join: r in Round,
        on: n.round_id == r.id,
        where: r.campaign_id == ^campaign_id,
        select: count(n.id)

    total = Repo.one(query, prefix: tenant) || 0

    # Count unique nominees
    unique_query =
      from n in Nomination,
        join: r in Round,
        on: n.round_id == r.id,
        where: r.campaign_id == ^campaign_id,
        select: count(n.nominee_id, :distinct)

    unique_nominees = Repo.one(unique_query, prefix: tenant) || 0

    # Count unique nominators
    nominator_query =
      from n in Nomination,
        join: r in Round,
        on: n.round_id == r.id,
        where: r.campaign_id == ^campaign_id,
        select: count(n.nominator_id, :distinct)

    unique_nominators = Repo.one(nominator_query, prefix: tenant) || 0

    %{
      total: total,
      unique_nominees: unique_nominees,
      unique_nominators: unique_nominators,
      avg_per_nominator:
        if(unique_nominators > 0, do: Float.round(total / unique_nominators, 1), else: 0.0)
    }
  end

  @doc """
  Gets convergence statistics (distribution of nomination counts).
  """
  def get_convergence_stats(tenant) do
    # Get nomination counts per person
    query =
      from n in Nomination,
        group_by: n.nominee_id,
        select: {n.nominee_id, count(n.id)}

    counts =
      Repo.all(query, prefix: tenant)
      |> Enum.map(fn {_id, count} -> count end)

    if Enum.empty?(counts) do
      %{
        max: 0,
        avg: 0.0,
        median: 0,
        top_5_threshold: 0,
        distribution: []
      }
    else
      sorted = Enum.sort(counts, :desc)
      total = length(sorted)

      %{
        max: Enum.max(counts),
        avg: Float.round(Enum.sum(counts) / total, 1),
        median: Enum.at(sorted, div(total, 2)),
        top_5_threshold: Enum.at(sorted, min(4, total - 1)),
        distribution: build_distribution(counts)
      }
    end
  end

  defp build_distribution(counts) do
    counts
    |> Enum.frequencies()
    |> Enum.sort_by(fn {count, _freq} -> count end, :desc)
    |> Enum.take(10)
    |> Enum.map(fn {count, freq} -> %{nominations: count, people: freq} end)
  end

  # =============================================================================
  # Round Statistics
  # =============================================================================

  @doc """
  Gets detailed statistics for a specific round.
  """
  def get_round_stats(tenant, round_id) do
    contacts = get_round_contacts_stats(tenant, round_id)
    nominations = get_round_nominations_stats(tenant, round_id)
    email_funnel = get_email_funnel(tenant, round_id)

    %{
      contacts: contacts,
      nominations: nominations,
      email_funnel: email_funnel
    }
  end

  defp get_round_contacts_stats(tenant, round_id) do
    query =
      from c in Contact,
        where: c.round_id == ^round_id,
        select: %{
          total: count(c.id),
          responded: count(c.responded_at)
        }

    case Repo.one(query, prefix: tenant) do
      nil ->
        %{total: 0, responded: 0, pending: 0, response_rate: 0.0}

      stats ->
        %{
          total: stats.total,
          responded: stats.responded,
          pending: stats.total - stats.responded,
          response_rate:
            if(stats.total > 0,
              do: Float.round(stats.responded / stats.total * 100, 1),
              else: 0.0
            )
        }
    end
  end

  defp get_round_nominations_stats(tenant, round_id) do
    query =
      from n in Nomination,
        where: n.round_id == ^round_id,
        select: count(n.id)

    total = Repo.one(query, prefix: tenant) || 0

    unique_query =
      from n in Nomination,
        where: n.round_id == ^round_id,
        select: count(n.nominee_id, :distinct)

    unique = Repo.one(unique_query, prefix: tenant) || 0

    %{total: total, unique_nominees: unique}
  end

  defp get_email_funnel(tenant, round_id) do
    query =
      from c in Contact,
        where: c.round_id == ^round_id,
        select: %{
          sent: count(c.invited_at),
          delivered: count(c.delivered_at),
          opened: count(c.opened_at),
          clicked: count(c.clicked_at),
          responded: count(c.responded_at)
        }

    Repo.one(query, prefix: tenant) ||
      %{sent: 0, delivered: 0, opened: 0, clicked: 0, responded: 0}
  end

  # =============================================================================
  # People Statistics
  # =============================================================================

  @doc """
  Gets the top nominees by nomination count.
  """
  def get_top_nominees(tenant, limit \\ 10) do
    query =
      from n in Nomination,
        join: p in Person,
        on: n.nominee_id == p.id,
        group_by: [p.id, p.name, p.email, p.source],
        order_by: [desc: count(n.id)],
        limit: ^limit,
        select: %{
          id: p.id,
          name: p.name,
          email: p.email,
          source: p.source,
          nomination_count: count(n.id)
        }

    Repo.all(query, prefix: tenant)
  end

  @doc """
  Gets the most active nominators.
  """
  def get_top_nominators(tenant, limit \\ 10) do
    query =
      from n in Nomination,
        join: p in Person,
        on: n.nominator_id == p.id,
        group_by: [p.id, p.name, p.email],
        order_by: [desc: count(n.id)],
        limit: ^limit,
        select: %{
          id: p.id,
          name: p.name,
          email: p.email,
          nominations_made: count(n.id)
        }

    Repo.all(query, prefix: tenant)
  end
end
