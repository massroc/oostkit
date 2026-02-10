defmodule PortalWeb.Api.AuthControllerTest do
  use PortalWeb.ConnCase, async: true

  import Portal.AccountsFixtures

  @api_key "test_internal_api_key"

  defp api_conn(conn) do
    conn
    |> put_req_header("authorization", "Bearer #{@api_key}")
    |> put_req_header("content-type", "application/json")
  end

  describe "POST /api/internal/auth/validate" do
    test "valid token returns 200 with user data", %{conn: conn} do
      user = user_fixture()
      token = Portal.Accounts.generate_user_session_token(user)
      encoded = Base.url_encode64(token)

      resp =
        conn
        |> api_conn()
        |> post(~p"/api/internal/auth/validate", %{token: encoded})
        |> json_response(200)

      assert resp["valid"] == true
      assert resp["user"]["id"] == user.id
      assert resp["user"]["email"] == user.email
      assert resp["user"]["role"] == user.role
      assert resp["user"]["enabled"] == true
    end

    test "invalid token returns 401", %{conn: conn} do
      encoded = Base.url_encode64("invalid_token_data")

      resp =
        conn
        |> api_conn()
        |> post(~p"/api/internal/auth/validate", %{token: encoded})
        |> json_response(401)

      assert resp["valid"] == false
      assert resp["error"] == "invalid_token"
    end

    test "disabled user returns 401", %{conn: conn} do
      user = user_fixture()
      {:ok, _} = Portal.Accounts.disable_user(user)
      token = Portal.Accounts.generate_user_session_token(user)
      encoded = Base.url_encode64(token)

      resp =
        conn
        |> api_conn()
        |> post(~p"/api/internal/auth/validate", %{token: encoded})
        |> json_response(401)

      assert resp["valid"] == false
    end

    test "missing token returns 400", %{conn: conn} do
      resp =
        conn
        |> api_conn()
        |> post(~p"/api/internal/auth/validate", %{})
        |> json_response(400)

      assert resp["valid"] == false
      assert resp["error"] == "missing_token"
    end

    test "missing API key returns 403", %{conn: conn} do
      conn
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/internal/auth/validate", %{token: "anything"})
      |> json_response(403)
    end

    test "wrong API key returns 403", %{conn: conn} do
      conn
      |> put_req_header("authorization", "Bearer wrong_key")
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/internal/auth/validate", %{token: "anything"})
      |> json_response(403)
    end
  end
end
