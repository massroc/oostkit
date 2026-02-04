defmodule WrtWeb.Org.ExportController do
  use WrtWeb, :controller

  alias Wrt.Campaigns
  alias Wrt.People

  plug WrtWeb.Plugs.TenantPlug
  plug WrtWeb.Plugs.RequireOrgAdmin

  def csv(conn, %{"campaign_id" => campaign_id}) do
    tenant = conn.assigns.tenant

    campaign = Campaigns.get_campaign!(tenant, campaign_id)
    people_with_counts = People.list_people_with_nomination_counts(tenant)

    csv_content = generate_csv(people_with_counts)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"#{slugify(campaign.name)}-results.csv\""
    )
    |> send_resp(200, csv_content)
  end

  def pdf(conn, %{"campaign_id" => campaign_id}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    campaign = Campaigns.get_campaign!(tenant, campaign_id)
    people_with_counts = People.list_people_with_nomination_counts(tenant)
    nominees = Enum.filter(people_with_counts, fn p -> p.nomination_count > 0 end)

    # For now, generate a simple HTML report that can be printed as PDF
    # In production, you might use a library like Chromic PDF or similar
    html_content = generate_report_html(org, campaign, nominees)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html_content)
  end

  defp generate_csv(people) do
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
    |> Enum.join("\n")
  end

  defp escape_csv(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end

  defp escape_csv(value), do: to_string(value)

  defp slugify(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp generate_report_html(org, campaign, nominees) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>#{campaign.name} - Results Report</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        h2 { color: #666; margin-top: 30px; }
        .meta { color: #666; margin-bottom: 20px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f5f5f5; font-weight: bold; }
        tr:nth-child(even) { background-color: #fafafa; }
        .rank { font-weight: bold; color: #4338ca; }
        .nominations { font-weight: bold; color: #059669; }
        @media print {
          body { margin: 20px; }
          table { page-break-inside: auto; }
          tr { page-break-inside: avoid; }
        }
      </style>
    </head>
    <body>
      <h1>#{campaign.name}</h1>
      <p class="meta">
        Organisation: #{org.name}<br>
        Generated: #{Calendar.strftime(DateTime.utc_now(), "%B %d, %Y at %I:%M %p UTC")}
      </p>

      <h2>Convergence Results</h2>
      <p>People ranked by number of nominations received.</p>

      <table>
        <thead>
          <tr>
            <th>Rank</th>
            <th>Name</th>
            <th>Email</th>
            <th>Source</th>
            <th>Nominations</th>
          </tr>
        </thead>
        <tbody>
          #{generate_table_rows(nominees)}
        </tbody>
      </table>

      <p style="margin-top: 30px; color: #999; font-size: 12px;">
        Total nominees: #{length(nominees)}<br>
        Total nominations: #{Enum.sum(Enum.map(nominees, & &1.nomination_count))}
      </p>
    </body>
    </html>
    """
  end

  defp generate_table_rows(nominees) do
    nominees
    |> Enum.with_index(1)
    |> Enum.map(fn {person, rank} ->
      """
      <tr>
        <td class="rank">#{rank}</td>
        <td>#{html_escape(person.name)}</td>
        <td>#{html_escape(person.email)}</td>
        <td>#{person.source}</td>
        <td class="nominations">#{person.nomination_count}</td>
      </tr>
      """
    end)
    |> Enum.join("\n")
  end

  defp html_escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp html_escape(text), do: to_string(text)
end
