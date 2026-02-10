defmodule PortalWeb.Admin.UsersLiveTest do
  use PortalWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Portal.AccountsFixtures

  describe "authorization" do
    test "unauthenticated user redirects to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/users")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "session manager redirects to / with flash", %{conn: conn} do
      session_manager = session_manager_fixture()

      assert {:error, redirect} =
               conn
               |> log_in_user(session_manager)
               |> live(~p"/admin/users")

      assert {:redirect, %{to: "/", flash: flash}} = redirect
      assert %{"error" => "You must be a super admin to access this page."} = flash
    end

    test "disabled super admin redirects to /", %{conn: conn} do
      admin = super_admin_fixture()
      {:ok, _} = Portal.Accounts.disable_user(admin)

      assert {:error, redirect} =
               conn
               |> log_in_user(admin)
               |> live(~p"/admin/users")

      assert {:redirect, %{to: "/", flash: flash}} = redirect
      assert %{"error" => "You must be a super admin to access this page."} = flash
    end
  end

  describe "index (listing users)" do
    setup :register_and_log_in_super_admin

    test "super admin sees users listed", %{conn: conn, user: admin} do
      sm = session_manager_fixture(%{email: "sm@example.com"})

      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      assert html =~ admin.email
      assert html =~ sm.email
    end

    test "role badges display correctly", %{conn: conn} do
      session_manager_fixture(%{email: "sm@example.com"})

      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      assert html =~ "Super Admin"
      assert html =~ "Session Manager"
    end

    test "enabled/disabled status badges display correctly", %{conn: conn} do
      sm = session_manager_fixture(%{email: "disabled@example.com"})
      {:ok, _} = Portal.Accounts.disable_user(sm)

      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      assert html =~ "Enabled"
      assert html =~ "Disabled"
    end
  end

  describe "create user (/admin/users/new)" do
    setup :register_and_log_in_super_admin

    test "renders create form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/users/new")

      assert html =~ "Create New User"
      assert html =~ "Email"
      assert html =~ "Name"
    end

    test "creates session manager with valid email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      lv
      |> form("form", user: %{email: "newuser@example.com", name: "New User"})
      |> render_submit()

      assert_patch(lv, ~p"/admin/users")
      assert render(lv) =~ "newuser@example.com"
      assert render(lv) =~ "User created successfully."
    end

    test "shows error for duplicate email", %{conn: conn} do
      session_manager_fixture(%{email: "existing@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      html =
        lv
        |> form("form", user: %{email: "existing@example.com"})
        |> render_submit()

      assert html =~ "has already been taken"
    end

    test "shows error for blank email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      html =
        lv
        |> form("form", user: %{email: ""})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "edit user (/admin/users/:id/edit)" do
    setup :register_and_log_in_super_admin

    test "renders edit form pre-populated", %{conn: conn} do
      sm = session_manager_fixture(%{email: "edit-me@example.com"})
      {:ok, _user} = Portal.Accounts.update_user(sm, %{name: "Edit Me"})

      {:ok, _lv, html} = live(conn, ~p"/admin/users/#{sm.id}/edit")

      assert html =~ "Edit User"
      assert html =~ "edit-me@example.com"
      assert html =~ "Edit Me"
    end

    test "updates user name successfully", %{conn: conn} do
      sm = session_manager_fixture(%{email: "rename@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/admin/users/#{sm.id}/edit")

      lv
      |> form("form", user: %{name: "Updated Name", role: "session_manager"})
      |> render_submit()

      assert_patch(lv, ~p"/admin/users")
      assert render(lv) =~ "User updated successfully."
    end

    test "updates user role", %{conn: conn} do
      sm = session_manager_fixture(%{email: "promote@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/admin/users/#{sm.id}/edit")

      lv
      |> form("form", user: %{name: "", role: "super_admin"})
      |> render_submit()

      assert_patch(lv, ~p"/admin/users")
      html = render(lv)
      assert html =~ "User updated successfully."
    end
  end

  describe "toggle enabled/disabled" do
    setup :register_and_log_in_super_admin

    test "disable button works for another user", %{conn: conn} do
      sm = session_manager_fixture(%{email: "toggleme@example.com"})

      {:ok, lv, html} = live(conn, ~p"/admin/users")
      assert html =~ "toggleme@example.com"

      lv
      |> element(~s|button[phx-click="toggle_enabled"][phx-value-id="#{sm.id}"]|)
      |> render_click()

      html = render(lv)
      assert html =~ "User updated successfully."
    end

    test "enable button works for disabled user", %{conn: conn} do
      sm = session_manager_fixture(%{email: "enableme@example.com"})
      {:ok, _} = Portal.Accounts.disable_user(sm)

      {:ok, lv, _html} = live(conn, ~p"/admin/users")

      lv
      |> element(~s|button[phx-click="toggle_enabled"][phx-value-id="#{sm.id}"]|)
      |> render_click()

      html = render(lv)
      assert html =~ "User updated successfully."
    end

    test "no disable button for logged-in admin's own row", %{conn: conn, user: admin} do
      {:ok, _lv, html} = live(conn, ~p"/admin/users")

      # The admin's own row should not have a toggle button
      refute html =~ "phx-value-id=\"#{admin.id}\""
    end
  end

  describe "navigation" do
    setup :register_and_log_in_super_admin

    test "create user button navigates to /admin/users/new", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/admin/users")

      assert html =~ ~s|href="/admin/users/new"|

      lv
      |> element("a", "Create User")
      |> render_click()

      assert_patch(lv, ~p"/admin/users/new")
    end

    test "cancel link returns to /admin/users", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      lv
      |> element("a", "Cancel")
      |> render_click()

      assert_patch(lv, ~p"/admin/users")
    end
  end
end
