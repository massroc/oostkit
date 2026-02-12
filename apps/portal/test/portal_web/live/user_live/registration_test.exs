defmodule PortalWeb.UserLive.RegistrationTest do
  use PortalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Portal.AccountsFixtures

  describe "Registration page" do
    test "renders registration page with facilitator messaging", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Start running workshops with OOSTKit"
      assert html =~ "facilitator account"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, ~p"/home")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces", "name" => ""})

      assert result =~ "must have the @ sign and no spaces"
    end
  end

  describe "register user" do
    test "creates account with name and email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()

      form =
        form(lv, "#registration_form", user: %{"email" => email, "name" => "Test Facilitator"})

      {:ok, _lv, html} =
        render_submit(form)
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~
               ~r/An email was sent to .*, please access it to confirm your account/
    end

    test "creates account with organisation and referral source", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()

      form =
        form(lv, "#registration_form",
          user: %{
            "email" => email,
            "name" => "Test Facilitator",
            "organisation" => "Acme Corp",
            "referral_source" => "Conference"
          }
        )

      {:ok, _lv, _html} =
        render_submit(form)
        |> follow_redirect(conn, ~p"/users/log-in")

      user = Portal.Accounts.get_user_by_email(email)
      assert user.organisation == "Acme Corp"
      assert user.referral_source == "Conference"
      assert user.onboarding_completed
    end

    test "saves tool interests during registration", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()

      lv
      |> form("#registration_form",
        user: %{"email" => email, "name" => "Test"},
        tool_ids: ["workgroup_pulse", "wrt"]
      )
      |> render_submit()

      user = Portal.Accounts.get_user_by_email(email)
      interests = Portal.Accounts.list_user_tool_interests(user.id)
      assert "workgroup_pulse" in interests
      assert "wrt" in interests
    end

    test "renders tool interest checkboxes", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Which tools are you interested in?"
      assert html =~ "Workgroup Pulse"
    end

    test "requires name", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> form("#registration_form", user: %{"email" => unique_user_email(), "name" => ""})
        |> render_submit()

      assert result =~ "can&#39;t be blank"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{"email" => user.email, "name" => "Test"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Log in")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert login_html =~ "Welcome back"
    end
  end
end
