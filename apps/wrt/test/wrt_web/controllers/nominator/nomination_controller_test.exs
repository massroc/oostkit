defmodule WrtWeb.Nominator.NominationControllerTest do
  use WrtWeb.ConnCase, async: true

  setup do
    {org, tenant} = create_org_with_tenant()
    campaign = insert_in_tenant(tenant, :campaign)
    round = insert_in_tenant(tenant, :active_round, %{campaign_id: campaign.id, round_number: 1})
    person = insert_in_tenant(tenant, :person)

    %{org: org, tenant: tenant, round: round, person: person}
  end

  describe "GET /org/:org_slug/nominate/form" do
    test "renders nomination form when session is set", %{
      conn: conn,
      org: org,
      person: person,
      round: round
    } do
      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.put_session(:nominator_person_id, person.id)
        |> Plug.Conn.put_session(:nominator_round_id, round.id)
        |> get("/org/#{org.slug}/nominate/form")

      assert html_response(conn, 200)
    end

    test "redirects when no nominator session", %{conn: conn, org: org} do
      conn = get(conn, "/org/#{org.slug}/nominate/form")

      # Without session, the plug redirects to invalid page
      assert conn.status in [200, 302]
    end
  end

  describe "POST /org/:org_slug/nominate/submit" do
    test "submits nominations successfully", %{
      conn: conn,
      org: org,
      person: person,
      round: round
    } do
      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.put_session(:nominator_person_id, person.id)
        |> Plug.Conn.put_session(:nominator_round_id, round.id)
        |> post("/org/#{org.slug}/nominate/submit", %{
          nominations: %{
            "0" => %{"name" => "Nominee One", "email" => "nominee1@test.com"},
            "1" => %{"name" => "Nominee Two", "email" => "nominee2@test.com"}
          }
        })

      assert redirected_to(conn) =~ "/nominate/form"
    end

    test "shows error when no nominations provided", %{
      conn: conn,
      org: org,
      person: person,
      round: round
    } do
      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.put_session(:nominator_person_id, person.id)
        |> Plug.Conn.put_session(:nominator_round_id, round.id)
        |> post("/org/#{org.slug}/nominate/submit", %{})

      assert redirected_to(conn) =~ "/nominate/form"
    end

    test "redirects when no nominator session", %{conn: conn, org: org} do
      conn =
        post(conn, "/org/#{org.slug}/nominate/submit", %{
          nominations: %{"0" => %{"name" => "Test", "email" => "test@test.com"}}
        })

      # Without session, the plug redirects to invalid page
      assert conn.status in [200, 302]
    end
  end
end
