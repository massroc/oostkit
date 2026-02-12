defmodule PortalWeb.UserLive.SettingsTest do
  use PortalWeb.ConnCase, async: true

  alias Portal.Accounts
  import Phoenix.LiveViewTest
  import Portal.AccountsFixtures

  describe "Settings page" do
    test "renders settings page with profile, email, and password sections", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/settings")

      assert html =~ "Save Profile"
      assert html =~ "Change Email"
      assert html =~ "Organisation"
      assert html =~ "Contact Preferences"
      assert html =~ "Save Preferences"
      assert html =~ "Danger zone"
      assert html =~ "Delete Account"
    end

    test "shows 'Add a password' when user has no password", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/settings")

      assert html =~ "Add a password"
    end

    test "shows 'Change password' when user has a password", %{conn: conn} do
      user = user_fixture() |> set_password()

      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/users/settings")

      assert html =~ "Change password"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "loads without sudo mode (no redirect)", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture(),
          token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -11, :minute)
        )
        |> live(~p"/users/settings")

      assert html =~ "Account Settings"
    end
  end

  describe "update profile form" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "updates name and organisation", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#profile_form", %{
          "user" => %{
            "name" => "Updated Name",
            "organisation" => "Acme Corp"
          }
        })
        |> render_submit()

      assert result =~ "Profile updated successfully."
    end

    test "validates name is required", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#profile_form")
        |> render_change(%{"user" => %{"name" => ""}})

      assert result =~ "can&#39;t be blank"
    end
  end

  describe "update contact preferences form" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders contact preferences section", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/settings")

      assert html =~ "Contact Preferences"
      assert html =~ "Product updates"
      assert html =~ "Save Preferences"
    end

    test "toggles product_updates on", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#contact_prefs_form", %{
          "user" => %{"product_updates" => "true"}
        })
        |> render_submit()

      assert result =~ "Contact preferences updated successfully."
      assert Accounts.get_user!(user.id).product_updates == true
    end

    test "toggles product_updates off", %{conn: conn, user: user} do
      Accounts.update_contact_prefs(user, %{product_updates: true})

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#contact_prefs_form", %{
          "user" => %{"product_updates" => "false"}
        })
        |> render_submit()

      assert result =~ "Contact preferences updated successfully."
      assert Accounts.get_user!(user.id).product_updates == false
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "updates the user email", %{conn: conn, user: user} do
      new_email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "user" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects to login when not in sudo mode", %{conn: conn} do
      user = user_fixture()

      conn =
        log_in_user(conn, user,
          token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -25, :minute)
        )

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "user" => %{"email" => unique_user_email()}
        })
        |> render_submit()

      assert {:error, {:live_redirect, %{to: "/users/log-in"}}} = result
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "user" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#email_form", %{
          "user" => %{"email" => user.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "updates the user password", %{conn: conn, user: user} do
      new_password = valid_user_password()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      form =
        form(lv, "#password_form", %{
          "user" => %{
            "email" => user.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/users/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_email_and_password(user.email, new_password)
    end

    test "redirects to login when not in sudo mode", %{conn: conn} do
      user = user_fixture()

      conn =
        log_in_user(conn, user,
          token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -25, :minute)
        )

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#password_form", %{
          "user" => %{
            "password" => valid_user_password(),
            "password_confirmation" => valid_user_password()
          }
        })
        |> render_submit()

      assert {:error, {:live_redirect, %{to: "/users/log-in"}}} = result
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#password_form", %{
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end
  end

  describe "delete account" do
    test "deletes account when in sudo mode", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      form = form(lv, "#delete_account_form")
      render_submit(form)

      delete_conn = follow_trigger_action(form, conn)

      assert redirected_to(delete_conn) == ~p"/"
      assert Phoenix.Flash.get(delete_conn.assigns.flash, :info) =~ "deleted"
      refute Accounts.get_user_by_email(user.email)
    end

    test "redirects to login when not in sudo mode", %{conn: conn} do
      user = user_fixture()

      conn =
        log_in_user(conn, user,
          token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -25, :minute)
        )

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      result =
        lv
        |> form("#delete_account_form")
        |> render_submit()

      assert {:error, {:live_redirect, %{to: "/users/log-in"}}} = result
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{conn: log_in_user(conn, user), token: token, email: email, user: user}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm-email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/users/settings/confirm-email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm-email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/users/settings/confirm-email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
