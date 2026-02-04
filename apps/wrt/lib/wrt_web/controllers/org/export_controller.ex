defmodule WrtWeb.Org.ExportController do
  @moduledoc """
  Handles data exports for campaigns.

  Supports:
  - CSV export with filtering options
  - PDF report generation using ChromicPDF
  """
  use WrtWeb, :controller

  alias Wrt.Campaigns
  alias Wrt.People
  alias Wrt.Rounds

  plug WrtWeb.Plugs.TenantPlug
  plug WrtWeb.Plugs.RequireOrgAdmin

  @doc """
  Exports campaign data as CSV.

  Query params:
  - min_nominations: Minimum nomination count to include (default: 0)
  - source: Filter by source ("seed", "nominated", or "all")
  - round_id: Filter nominations by specific round
  """
  def csv(conn, %{"campaign_id" => campaign_id} = params) do
    tenant = conn.assigns.tenant

    campaign = Campaigns.get_campaign!(tenant, campaign_id)
    filters = parse_filters(params)

    people_with_counts = get_filtered_people(tenant, campaign_id, filters)

    csv_content = generate_csv(people_with_counts, filters)

    filename = build_filename(campaign.name, "csv", filters)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, csv_content)
  end

  @doc """
  Exports campaign report as PDF using ChromicPDF.
  """
  def pdf(conn, %{"campaign_id" => campaign_id} = params) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)
    filters = parse_filters(params)

    people_with_counts = get_filtered_people(tenant, campaign_id, filters)
    nominees = Enum.filter(people_with_counts, fn p -> p.nomination_count > 0 end)
    rounds = Rounds.list_rounds(tenant, campaign_id)
    round_stats = get_round_statistics(tenant, rounds)

    html_content = generate_report_html(org, campaign, nominees, rounds, round_stats, filters)
    filename = build_filename(campaign.name, "pdf", filters)

    # Try to generate PDF with ChromicPDF, fallback to HTML if not available
    case generate_pdf(html_content) do
      {:ok, pdf_binary} ->
        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
        |> send_resp(200, pdf_binary)

      {:error, _reason} ->
        # Fallback to HTML for printing
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, html_content)
    end
  end

  # Filter parsing

  defp parse_filters(params) do
    %{
      min_nominations: parse_int(params["min_nominations"], 0),
      source: params["source"] || "all",
      round_id: parse_int(params["round_id"], nil)
    }
  end

  defp parse_int(nil, default), do: default
  defp parse_int("", default), do: default

  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_int(value, _default) when is_integer(value), do: value

  # Data fetching with filters

  defp get_filtered_people(tenant, _campaign_id, filters) do
    people_with_counts = People.list_people_with_nomination_counts(tenant)

    people_with_counts
    |> filter_by_source(filters.source)
    |> filter_by_min_nominations(filters.min_nominations)
  end

  defp filter_by_source(people, "all"), do: people
  defp filter_by_source(people, source), do: Enum.filter(people, &(&1.source == source))

  defp filter_by_min_nominations(people, 0), do: people

  defp filter_by_min_nominations(people, min) do
    Enum.filter(people, &(&1.nomination_count >= min))
  end

  defp get_round_statistics(tenant, rounds) do
    Enum.map(rounds, fn round ->
      stats = Rounds.count_contacts(tenant, round.id)

      %{
        round: round,
        contacts: stats.total,
        responded: stats.responded,
        response_rate:
          if(stats.total > 0, do: Float.round(stats.responded / stats.total * 100, 1), else: 0)
      }
    end)
  end

  # Filename generation

  defp build_filename(campaign_name, extension, filters) do
    base = slugify(campaign_name)

    suffix =
      cond do
        filters.source != "all" -> "-#{filters.source}"
        filters.min_nominations > 0 -> "-min#{filters.min_nominations}"
        true -> ""
      end

    "#{base}-results#{suffix}.#{extension}"
  end

  defp slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  # CSV Generation

  defp generate_csv(people, _filters) do
    headers = ["Rank", "Name", "Email", "Source", "Nominations"]

    rows =
      people
      |> Enum.with_index(1)
      |> Enum.map(fn {person, rank} ->
        [
          to_string(rank),
          escape_csv(person.name),
          escape_csv(person.email),
          person.source,
          to_string(person.nomination_count)
        ]
      end)

    [Enum.join(headers, ",") | Enum.map(rows, &Enum.join(&1, ","))]
    |> Enum.join("\r\n")
  end

  defp escape_csv(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n", "\r"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end

  defp escape_csv(value), do: to_string(value)

  # PDF Generation

  defp generate_pdf(html_content) do
    if Code.ensure_loaded?(ChromicPDF) do
      ChromicPDF.print_to_pdf({:html, html_content},
        print_to_pdf: %{
          preferCSSPageSize: true,
          marginTop: 0.5,
          marginBottom: 0.5,
          marginLeft: 0.5,
          marginRight: 0.5
        }
      )
    else
      {:error, :chromic_pdf_not_available}
    end
  end

  # HTML Report Generation

  defp generate_report_html(org, campaign, nominees, rounds, round_stats, filters) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>#{html_escape(campaign.name)} - Results Report</title>
      <style>
        @page {
          size: A4;
          margin: 1.5cm;
        }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          line-height: 1.5;
          color: #1f2937;
          max-width: 210mm;
          margin: 0 auto;
          padding: 20px;
        }
        .header {
          border-bottom: 2px solid #4f46e5;
          padding-bottom: 20px;
          margin-bottom: 30px;
        }
        h1 { color: #1f2937; margin: 0 0 10px 0; font-size: 28px; }
        h2 { color: #4f46e5; margin-top: 30px; font-size: 20px; }
        .meta { color: #6b7280; font-size: 14px; }
        .summary-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 20px;
          margin: 20px 0;
        }
        .summary-card {
          background: #f9fafb;
          border: 1px solid #e5e7eb;
          border-radius: 8px;
          padding: 16px;
          text-align: center;
        }
        .summary-card .value {
          font-size: 32px;
          font-weight: bold;
          color: #4f46e5;
        }
        .summary-card .label {
          font-size: 12px;
          color: #6b7280;
          text-transform: uppercase;
        }
        table {
          border-collapse: collapse;
          width: 100%;
          margin-top: 15px;
          font-size: 13px;
        }
        th, td {
          border: 1px solid #e5e7eb;
          padding: 10px 12px;
          text-align: left;
        }
        th {
          background-color: #f9fafb;
          font-weight: 600;
          color: #374151;
        }
        tr:nth-child(even) { background-color: #f9fafb; }
        .rank { font-weight: bold; color: #4f46e5; }
        .nominations { font-weight: bold; color: #059669; }
        .source-seed { color: #2563eb; }
        .source-nominated { color: #7c3aed; }
        .filter-info {
          background: #fef3c7;
          border: 1px solid #fcd34d;
          border-radius: 6px;
          padding: 10px 15px;
          margin: 15px 0;
          font-size: 13px;
        }
        .footer {
          margin-top: 40px;
          padding-top: 20px;
          border-top: 1px solid #e5e7eb;
          font-size: 11px;
          color: #9ca3af;
        }
        @media print {
          body { padding: 0; }
          .summary-grid { page-break-inside: avoid; }
          table { page-break-inside: auto; }
          tr { page-break-inside: avoid; }
        }
      </style>
    </head>
    <body>
      <div class="header">
        <h1>#{html_escape(campaign.name)}</h1>
        <p class="meta">
          <strong>Organisation:</strong> #{html_escape(org.name)}<br>
          <strong>Generated:</strong> #{Calendar.strftime(DateTime.utc_now(), "%B %d, %Y at %I:%M %p UTC")}<br>
          <strong>Status:</strong> #{campaign.status}
        </p>
      </div>

      #{generate_filter_info(filters)}

      <h2>Campaign Summary</h2>
      <div class="summary-grid">
        <div class="summary-card">
          <div class="value">#{length(rounds)}</div>
          <div class="label">Rounds</div>
        </div>
        <div class="summary-card">
          <div class="value">#{length(nominees)}</div>
          <div class="label">Unique Nominees</div>
        </div>
        <div class="summary-card">
          <div class="value">#{Enum.sum(Enum.map(nominees, & &1.nomination_count))}</div>
          <div class="label">Total Nominations</div>
        </div>
      </div>

      #{generate_rounds_section(round_stats)}

      <h2>Convergence Results</h2>
      <p>People ranked by number of nominations received.</p>

      #{generate_results_table(nominees)}

      <div class="footer">
        <p>
          This report was generated by the Workshop Referral Tool.<br>
          Total records: #{length(nominees)} |
          Generated: #{Calendar.strftime(DateTime.utc_now(), "%Y-%m-%d %H:%M:%S UTC")}
        </p>
      </div>
    </body>
    </html>
    """
  end

  defp generate_filter_info(filters) do
    active_filters = []

    active_filters =
      if filters.source != "all",
        do: ["Source: #{filters.source}" | active_filters],
        else: active_filters

    active_filters =
      if filters.min_nominations > 0,
        do: ["Min nominations: #{filters.min_nominations}" | active_filters],
        else: active_filters

    if Enum.empty?(active_filters) do
      ""
    else
      """
      <div class="filter-info">
        <strong>Filters applied:</strong> #{Enum.join(active_filters, ", ")}
      </div>
      """
    end
  end

  defp generate_rounds_section([]), do: ""

  defp generate_rounds_section(round_stats) do
    rows =
      round_stats
      |> Enum.map(fn stat ->
        """
        <tr>
          <td>Round #{stat.round.round_number}</td>
          <td>#{format_status(stat.round.status)}</td>
          <td>#{stat.contacts}</td>
          <td>#{stat.responded}</td>
          <td>#{stat.response_rate}%</td>
        </tr>
        """
      end)
      |> Enum.join("\n")

    """
    <h2>Round Statistics</h2>
    <table>
      <thead>
        <tr>
          <th>Round</th>
          <th>Status</th>
          <th>Contacts</th>
          <th>Responded</th>
          <th>Response Rate</th>
        </tr>
      </thead>
      <tbody>
        #{rows}
      </tbody>
    </table>
    """
  end

  defp format_status("active"), do: "<span style=\"color: #059669;\">Active</span>"
  defp format_status("closed"), do: "<span style=\"color: #6b7280;\">Closed</span>"
  defp format_status(status), do: status

  defp generate_results_table([]) do
    "<p style=\"color: #6b7280;\">No nominees match the current filters.</p>"
  end

  defp generate_results_table(nominees) do
    rows =
      nominees
      |> Enum.with_index(1)
      |> Enum.map(fn {person, rank} ->
        source_class = if person.source == "seed", do: "source-seed", else: "source-nominated"

        """
        <tr>
          <td class="rank">#{rank}</td>
          <td>#{html_escape(person.name)}</td>
          <td>#{html_escape(person.email)}</td>
          <td class="#{source_class}">#{person.source}</td>
          <td class="nominations">#{person.nomination_count}</td>
        </tr>
        """
      end)
      |> Enum.join("\n")

    """
    <table>
      <thead>
        <tr>
          <th style="width: 60px;">Rank</th>
          <th>Name</th>
          <th>Email</th>
          <th style="width: 100px;">Source</th>
          <th style="width: 100px;">Nominations</th>
        </tr>
      </thead>
      <tbody>
        #{rows}
      </tbody>
    </table>
    """
  end

  defp html_escape(nil), do: ""

  defp html_escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp html_escape(text), do: to_string(text)
end
