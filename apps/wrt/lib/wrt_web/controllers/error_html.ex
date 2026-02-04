defmodule WrtWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.
  """
  use WrtWeb, :html

  embed_templates "error_html/*"

  # Fallback for any other error
  def render(template, assigns) do
    status_code = assigns[:status] || extract_status(template)

    assigns =
      assigns
      |> Map.put(:status_code, status_code)
      |> Map.put(:message, status_message(status_code))

    render_error_page(assigns)
  end

  defp extract_status(template) do
    case Integer.parse(template) do
      {code, _} -> code
      :error -> 500
    end
  end

  defp status_message(404), do: "The page you're looking for doesn't exist."
  defp status_message(401), do: "You need to be logged in to access this page."
  defp status_message(403), do: "You don't have permission to access this page."
  defp status_message(429), do: "Too many requests. Please slow down and try again."
  defp status_message(500), do: "Something went wrong on our end. We've been notified."
  defp status_message(503), do: "Service temporarily unavailable. Please try again later."
  defp status_message(_), do: "An unexpected error occurred."

  defp render_error_page(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Error {@status_code} - Workshop Referral Tool</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.5;
            color: #1f2937;
            background: #f9fafb;
            margin: 0;
            padding: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
          }
          .container {
            text-align: center;
            padding: 40px;
            max-width: 500px;
          }
          .error-code {
            font-size: 120px;
            font-weight: bold;
            color: #e5e7eb;
            margin: 0;
            line-height: 1;
          }
          h1 {
            font-size: 24px;
            margin: 20px 0 10px;
            color: #1f2937;
          }
          p {
            color: #6b7280;
            margin: 0 0 30px;
          }
          .button {
            display: inline-block;
            background: #4f46e5;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 6px;
            font-weight: 500;
          }
          .button:hover {
            background: #4338ca;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <p class="error-code">{@status_code}</p>
          <h1>Oops!</h1>
          <p>{@message}</p>
          <a href="/" class="button">Go Home</a>
        </div>
      </body>
    </html>
    """
  end
end
