defmodule PortalWeb.OnboardingController do
  @moduledoc """
  Handles onboarding form submissions from the dashboard.
  """
  use PortalWeb, :controller

  alias Portal.Accounts

  def save(conn, %{"onboarding" => params}) do
    user = conn.assigns.current_scope.user
    tool_ids = Map.get(params, "tool_ids", [])

    case Accounts.complete_onboarding(user, params, tool_ids) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Thanks for sharing! Welcome to OOSTKit.")
        |> redirect(to: ~p"/home")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Something went wrong. Please try again.")
        |> redirect(to: ~p"/home")
    end
  end

  def skip(conn, _params) do
    user = conn.assigns.current_scope.user

    case Accounts.skip_onboarding(user) do
      {:ok, _user} ->
        conn |> redirect(to: ~p"/home")

      {:error, _changeset} ->
        conn |> redirect(to: ~p"/home")
    end
  end
end
