defmodule PortalWeb.UserLive.ForgotPasswordTest do
  use PortalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Portal.AccountsFixtures

  describe "Forgot password page" do
    test "renders forgot password page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/forgot-password")

      assert html =~ "Forgot your password?"
      assert html =~ "Send reset link"
      assert html =~ "Back to log in"
    end

    test "sends reset email for valid user", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      {:ok, _lv, html} =
        lv
        |> form("#reset_password_form", user: %{"email" => user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "you will receive password reset instructions"
    end

    test "does not reveal if email is not registered", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/forgot-password")

      {:ok, _lv, html} =
        lv
        |> form("#reset_password_form", user: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "you will receive password reset instructions"
    end
  end
end
