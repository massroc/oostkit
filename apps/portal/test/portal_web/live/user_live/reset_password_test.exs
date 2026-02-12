defmodule PortalWeb.UserLive.ResetPasswordTest do
  use PortalWeb.ConnCase, async: true

  alias Portal.Accounts
  import Phoenix.LiveViewTest
  import Portal.AccountsFixtures

  setup do
    user = user_fixture() |> set_password()

    token =
      extract_user_token(fn url ->
        Accounts.deliver_password_reset_instructions(user, url)
      end)

    %{user: user, token: token}
  end

  describe "Reset password page" do
    test "renders reset password page with valid token", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/users/reset-password/#{token}")

      assert html =~ "Reset your password"
      assert html =~ "New password"
    end

    test "redirects with invalid token", %{conn: conn} do
      {:ok, _lv, html} =
        live(conn, ~p"/users/reset-password/invalid-token")
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "Reset password link is invalid or it has expired"
    end

    test "resets password with valid data", %{conn: conn, user: user, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset-password/#{token}")

      new_password = "new_valid_password123"

      {:ok, _lv, html} =
        lv
        |> form("#reset_password_form",
          user: %{
            "password" => new_password,
            "password_confirmation" => new_password
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "Password reset successfully"
      assert Accounts.get_user_by_email_and_password(user.email, new_password)
    end

    test "renders errors for invalid data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset-password/#{token}")

      result =
        lv
        |> form("#reset_password_form",
          user: %{
            "password" => "short",
            "password_confirmation" => "does not match"
          }
        )
        |> render_submit()

      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "validates password on change", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset-password/#{token}")

      result =
        lv
        |> element("#reset_password_form")
        |> render_change(user: %{"password" => "short", "password_confirmation" => ""})

      assert result =~ "should be at least 12 character(s)"
    end
  end
end
