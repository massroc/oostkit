defmodule PortalWeb.Admin.SignupsController do
  @moduledoc """
  Controller for admin signup data exports.
  """
  use PortalWeb, :controller

  alias Portal.Marketing

  def export(conn, _params) do
    signups = Marketing.list_interest_signups()
    csv = build_csv(signups)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      ~s|attachment; filename="signups-#{Date.utc_today()}.csv"|
    )
    |> send_resp(200, csv)
  end

  defp build_csv(signups) do
    header = "Name,Email,Context,Date\r\n"

    rows =
      Enum.map_join(signups, "\r\n", fn signup ->
        [
          signup.name || "",
          signup.email,
          signup.context || "",
          Calendar.strftime(signup.inserted_at, "%Y-%m-%d %H:%M:%S")
        ]
        |> Enum.map_join(",", &csv_escape/1)
      end)

    header <> rows
  end

  defp csv_escape(value) do
    value = to_string(value)

    if String.contains?(value, [",", "\"", "\n", "\r"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end
end
