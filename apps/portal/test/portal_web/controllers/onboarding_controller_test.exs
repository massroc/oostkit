defmodule PortalWeb.OnboardingControllerTest do
  use PortalWeb.ConnCase, async: true

  import Portal.AccountsFixtures

  alias Portal.Accounts

  describe "save onboarding" do
    test "saves profile data and tool interests", %{conn: conn} do
      user = user_fixture()
      refute user.onboarding_completed

      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/onboarding", %{
          "onboarding" => %{
            "organisation" => "Acme Corp",
            "referral_source" => "Conference",
            "tool_ids" => ["workgroup_pulse", "wrt"]
          }
        })

      assert redirected_to(conn) == ~p"/home"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Thanks for sharing"

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.onboarding_completed
      assert updated_user.organisation == "Acme Corp"
      assert updated_user.referral_source == "Conference"

      interests = Accounts.list_user_tool_interests(user.id)
      assert "workgroup_pulse" in interests
      assert "wrt" in interests
    end

    test "saves without tool interests", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/onboarding", %{
          "onboarding" => %{
            "organisation" => "Solo Practitioner",
            "referral_source" => ""
          }
        })

      assert redirected_to(conn) == ~p"/home"

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.onboarding_completed
      assert updated_user.organisation == "Solo Practitioner"
    end

    test "requires authentication", %{conn: conn} do
      conn = post(conn, ~p"/onboarding", %{"onboarding" => %{}})
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "skip onboarding" do
    test "marks onboarding as completed without saving data", %{conn: conn} do
      user = user_fixture()
      refute user.onboarding_completed

      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/onboarding/skip")

      assert redirected_to(conn) == ~p"/home"

      updated_user = Accounts.get_user!(user.id)
      assert updated_user.onboarding_completed
      assert is_nil(updated_user.organisation)
    end

    test "requires authentication", %{conn: conn} do
      conn = post(conn, ~p"/onboarding/skip")
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end
end
