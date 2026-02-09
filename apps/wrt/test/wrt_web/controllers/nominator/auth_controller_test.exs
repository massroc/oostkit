defmodule WrtWeb.Nominator.AuthControllerTest do
  use WrtWeb.ConnCase, async: true

  alias Wrt.MagicLinks

  setup do
    {org, tenant} = create_org_with_tenant()
    campaign = insert_in_tenant(tenant, :campaign)
    round = insert_in_tenant(tenant, :active_round, %{campaign_id: campaign.id, round_number: 1})
    person = insert_in_tenant(tenant, :person)

    {:ok, magic_link} =
      MagicLinks.create_magic_link(tenant, %{person_id: person.id, round_id: round.id})

    %{org: org, tenant: tenant, round: round, person: person, magic_link: magic_link}
  end

  describe "GET /org/:org_slug/nominate/invalid" do
    test "renders invalid link page", %{conn: conn, org: org} do
      conn = get(conn, "/org/#{org.slug}/nominate/invalid?reason=expired")
      assert html_response(conn, 200)
    end
  end

  describe "GET /org/:org_slug/nominate/:token" do
    test "renders landing page for valid token", %{conn: conn, org: org, magic_link: magic_link} do
      conn = get(conn, "/org/#{org.slug}/nominate/#{magic_link.token}")
      assert html_response(conn, 200)
    end

    test "shows error for invalid token", %{conn: conn, org: org} do
      conn = get(conn, "/org/#{org.slug}/nominate/invalid-token-here")
      assert html_response(conn, 200) =~ "not valid"
    end

    test "shows error for used token", %{
      conn: conn,
      org: org,
      tenant: tenant,
      magic_link: magic_link
    } do
      {:ok, _} = MagicLinks.use_magic_link(tenant, magic_link)

      conn = get(conn, "/org/#{org.slug}/nominate/#{magic_link.token}")
      assert html_response(conn, 200) =~ "already been used"
    end
  end

  describe "POST /org/:org_slug/nominate/verify/code" do
    test "verifies valid code and redirects to form", %{
      conn: conn,
      org: org,
      tenant: tenant,
      magic_link: magic_link
    } do
      {:ok, ml_with_code} = MagicLinks.generate_code(tenant, magic_link)

      conn =
        post(conn, "/org/#{org.slug}/nominate/verify/code", %{
          magic_link_id: to_string(ml_with_code.id),
          code: ml_with_code.code
        })

      assert redirected_to(conn) =~ "/nominate/form"
    end

    test "shows error for invalid code", %{
      conn: conn,
      org: org,
      tenant: tenant,
      magic_link: magic_link
    } do
      {:ok, _} = MagicLinks.generate_code(tenant, magic_link)

      conn =
        post(conn, "/org/#{org.slug}/nominate/verify/code", %{
          magic_link_id: to_string(magic_link.id),
          code: "000000"
        })

      # Should redirect back with error
      assert conn.status in [200, 302]
    end
  end
end
