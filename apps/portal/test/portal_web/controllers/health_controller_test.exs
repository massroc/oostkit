defmodule PortalWeb.HealthControllerTest do
  use PortalWeb.ConnCase, async: true

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

      response = json_response(conn, 200)
      assert response["status"] == "ready"
      assert response["timestamp"]
      assert Map.has_key?(response, "checks")
    end

    test "includes database check status", %{conn: conn} do
      conn = get(conn, "/health/ready")

      response = json_response(conn, 200)
      assert response["checks"]["database"]["status"] == "ok"
    end
  end
end
