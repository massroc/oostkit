defmodule WrtWeb.HealthControllerTest do
  use WrtWeb.ConnCase, async: true

  describe "GET /health" do
    test "returns 200 with ok status", %{conn: conn} do
      conn = get(conn, "/health")

      assert json_response(conn, 200)["status"] == "ok"
      assert json_response(conn, 200)["timestamp"]
    end
  end

  describe "GET /health/ready" do
    test "returns response with checks", %{conn: conn} do
      conn = get(conn, "/health/ready")

      # In test mode, Oban runs inline and may not have a process,
      # so we accept either 200 or 503
      response = json_response(conn, conn.status)
      assert response["timestamp"]
      assert Map.has_key?(response, "checks")
    end

    test "includes database check status", %{conn: conn} do
      conn = get(conn, "/health/ready")

      response = json_response(conn, conn.status)
      assert Map.has_key?(response["checks"], "database")
      # Database should always be ok in tests
      assert response["checks"]["database"]["status"] == "ok"
    end

    test "includes oban check status", %{conn: conn} do
      conn = get(conn, "/health/ready")

      response = json_response(conn, conn.status)
      assert Map.has_key?(response["checks"], "oban")
    end
  end
end
