defmodule WrtWeb.Nominator.AuthController do
  @moduledoc """
  Handles nominator authentication via magic links.

  Flow:
  1. Nominator clicks link in invitation email (landing)
  2. System verifies token and shows landing page
  3. Nominator requests verification code (request_link)
  4. System sends code via email and shows verification form
  5. Nominator enters code (verify)
  6. System verifies code and creates session
  7. Redirect to nomination form
  """
  use WrtWeb, :controller

  alias Wrt.MagicLinks
  alias Wrt.Rounds
  alias Wrt.Workers.SendVerificationCode

  plug WrtWeb.Plugs.TenantPlug

  @doc """
  Shows an error page for invalid links.
  """
  def invalid(conn, _params) do
    org = conn.assigns.current_org

    render(conn, :invalid_link,
      page_title: "Invalid Link",
      org: org,
      reason: "The link you followed is not valid or has expired."
    )
  end

  @doc """
  Landing page when nominator clicks magic link from email.
  Verifies the token and shows options to continue.
  """
  def landing(conn, %{"token" => token}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    case MagicLinks.verify_token(tenant, token) do
      {:ok, magic_link} ->
        # Check if round is still active
        if Rounds.Round.active?(magic_link.round) do
          render(conn, :landing,
            page_title: "Welcome",
            org: org,
            person: magic_link.person,
            round: magic_link.round,
            token: token
          )
        else
          render(conn, :round_closed,
            page_title: "Round Closed",
            org: org
          )
        end

      {:error, :not_found} ->
        render(conn, :invalid_link,
          page_title: "Invalid Link",
          org: org,
          reason: "This link is not valid."
        )

      {:error, :already_used} ->
        render(conn, :invalid_link,
          page_title: "Link Already Used",
          org: org,
          reason: "This link has already been used. If you need to edit your nominations, please request a new link."
        )

      {:error, :expired} ->
        render(conn, :invalid_link,
          page_title: "Link Expired",
          org: org,
          reason: "This link has expired. Please request a new one."
        )
    end
  end

  @doc """
  Requests a verification code to be sent via email.
  """
  def request_link(conn, %{"token" => token}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    case MagicLinks.verify_token(tenant, token) do
      {:ok, magic_link} ->
        # Generate a new code
        case MagicLinks.generate_code(tenant, magic_link) do
          {:ok, magic_link_with_code} ->
            # Queue email sending job
            SendVerificationCode.enqueue(tenant, magic_link_with_code.id, org.id)

            render(conn, :verify_form,
              page_title: "Enter Verification Code",
              org: org,
              magic_link_id: magic_link_with_code.id,
              email: magic_link.person.email
            )

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to generate verification code. Please try again.")
            |> redirect(to: ~p"/org/#{org.slug}/nominate/#{token}")
        end

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Invalid or expired link.")
        |> redirect(to: ~p"/org/#{org.slug}/nominate/invalid")
    end
  end

  @doc """
  Verifies the code and creates a session.
  """
  def verify(conn, %{"magic_link_id" => magic_link_id, "code" => code}) do
    tenant = conn.assigns.tenant
    org = conn.assigns.current_org

    case MagicLinks.verify_code(tenant, magic_link_id, code) do
      {:ok, magic_link} ->
        # Mark the link as used
        {:ok, _} = MagicLinks.use_magic_link(tenant, magic_link)

        # Create nominator session
        conn
        |> put_session(:nominator_person_id, magic_link.person_id)
        |> put_session(:nominator_round_id, magic_link.round_id)
        |> configure_session(renew: true)
        |> put_flash(:info, "Welcome, #{magic_link.person.name}!")
        |> redirect(to: ~p"/org/#{org.slug}/nominate/form")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Invalid request. Please try again.")
        |> redirect(to: ~p"/org/#{org.slug}/nominate/invalid")

      {:error, :already_used} ->
        conn
        |> put_flash(:error, "This link has already been used.")
        |> redirect(to: ~p"/org/#{org.slug}/nominate/invalid")

      {:error, :code_expired} ->
        conn
        |> put_flash(:error, "Verification code has expired. Please request a new one.")
        |> redirect(to: ~p"/org/#{org.slug}/nominate/invalid")

      {:error, :invalid_code} ->
        # Re-render the form with error
        magic_link = MagicLinks.get_magic_link(tenant, magic_link_id)

        render(conn, :verify_form,
          page_title: "Enter Verification Code",
          org: org,
          magic_link_id: magic_link_id,
          email: magic_link && magic_link.person.email,
          error: "Invalid code. Please check and try again."
        )
    end
  end

  def verify(conn, %{"code" => _code}) do
    org = conn.assigns.current_org

    # Handle the case where code is in the URL path
    render(conn, :invalid_link,
      page_title: "Invalid Request",
      org: org,
      reason: "Invalid verification request. Please use the link from your email."
    )
  end
end
