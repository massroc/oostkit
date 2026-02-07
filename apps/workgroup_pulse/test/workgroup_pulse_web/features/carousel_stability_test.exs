defmodule WorkgroupPulseWeb.Features.CarouselStabilityTest do
  @moduledoc """
  Tests that the carousel stays on the correct slide (index 4) during
  scoring interactions. Regression tests for the carousel-reset bug where
  clicking buttons, selecting scores, or opening popups caused the
  carousel to jump back to slide 0.
  """
  use WorkgroupPulseWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulse.Workshops.{Question, Template}

  describe "carousel stays on slide 4 during scoring" do
    setup do
      slug = "carousel-test-#{System.unique_integer([:positive])}"

      template =
        Repo.insert!(%Template{
          name: "Carousel Test",
          slug: slug,
          version: "1.0.0",
          default_duration_minutes: 60
        })

      Repo.insert!(%Question{
        template_id: template.id,
        index: 0,
        title: "Balance Question",
        criterion_number: "1",
        criterion_name: "Test Criterion",
        explanation: "Test explanation for balance question",
        discussion_prompts: ["Discuss this", "Talk about that"],
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        optimal_value: 0
      })

      {:ok, session} =
        Sessions.create_session(template, duration_minutes: 60, timer_enabled: false)

      fac_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Facilitator", fac_token, is_facilitator: true)

      part_token = Ecto.UUID.generate()
      {:ok, _} = Sessions.join_session(session, "Alice", part_token)

      {:ok, session} = Sessions.start_session(session)
      {:ok, session} = Sessions.advance_to_scoring(session)

      %{session: session, fac_token: fac_token, part_token: part_token}
    end

    # Asserts carousel_index is 4 in both the socket assigns AND the rendered HTML.
    defp assert_carousel_on_slide_4(view) do
      # Check the rendered data-index attribute on the carousel element
      html = render(view)

      # Extract the data-index value from the workshop-carousel element
      assert html =~ ~r/id="workshop-carousel"[^>]*data-index="4"/s,
             "carousel data-index should be 4 in rendered HTML"
    end

    test "carousel is on slide 4 when entering scoring", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      assert_carousel_on_slide_4(view)
    end

    test "carousel stays on slide 4 after opening score overlay", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      view |> element("[phx-click='edit_my_score']") |> render_click()

      assert_carousel_on_slide_4(view)
    end

    test "carousel stays on slide 4 after selecting a score", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      view |> element("[phx-click='edit_my_score']") |> render_click()
      view |> element("button[phx-value-score='0']") |> render_click()

      assert_carousel_on_slide_4(view)
    end

    test "carousel stays on slide 4 after closing score overlay", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      view |> element("[phx-click='edit_my_score']") |> render_click()
      view |> element("button[phx-value-score='0']") |> render_click()
      view |> render_click("close_score_overlay")

      assert_carousel_on_slide_4(view)
    end

    test "carousel stays on slide 4 after completing turn", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      view |> element("[phx-click='edit_my_score']") |> render_click()
      view |> element("button[phx-value-score='0']") |> render_click()
      view |> render_click("complete_turn")

      assert_carousel_on_slide_4(view)
    end

    test "carousel stays on slide 4 after opening criterion popup", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      view |> render_click("show_criterion_info", %{"index" => "0"})

      assert_carousel_on_slide_4(view)
      assert render(view) =~ "Test explanation for balance question"
    end

    test "carousel stays on slide 4 after closing criterion popup", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      view |> render_click("show_criterion_info", %{"index" => "0"})
      view |> render_click("close_criterion_info")

      assert_carousel_on_slide_4(view)
      refute render(view) =~ "Test explanation for balance question"
    end

    test "score overlay renders outside the carousel", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      view |> element("[phx-click='edit_my_score']") |> render_click()
      html = render(view)

      # Find where the carousel ends and the overlay begins.
      # The carousel is id="workshop-carousel". The overlay has class="score-overlay-enter".
      # The overlay must appear AFTER the carousel's closing structure, not nested inside it.
      carousel_end = find_element_end(html, "workshop-carousel")
      overlay_start = find_string_pos(html, "score-overlay-enter")

      assert carousel_end != nil, "carousel element should exist"
      assert overlay_start != nil, "score overlay should exist"

      assert overlay_start > carousel_end,
             "score overlay should be after the carousel, not inside it"
    end

    test "criterion popup renders outside the carousel", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      view |> render_click("show_criterion_info", %{"index" => "0"})
      html = render(view)

      carousel_end = find_element_end(html, "workshop-carousel")
      popup_start = find_string_pos(html, "close_criterion_info")

      assert carousel_end != nil, "carousel element should exist"
      assert popup_start != nil, "criterion popup should exist"

      assert popup_start > carousel_end,
             "criterion popup should be after the carousel, not inside it"
    end

    test "full scoring flow keeps carousel on slide 4 throughout", %{
      conn: conn,
      session: session,
      fac_token: fac_token,
      part_token: part_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, fac_view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      assert_carousel_on_slide_4(fac_view)

      # Facilitator opens/closes criterion popup
      fac_view |> render_click("show_criterion_info", %{"index" => "0"})
      assert_carousel_on_slide_4(fac_view)

      fac_view |> render_click("close_criterion_info")
      assert_carousel_on_slide_4(fac_view)

      # Facilitator opens score overlay and picks a score
      fac_view |> element("[phx-click='edit_my_score']") |> render_click()
      assert_carousel_on_slide_4(fac_view)

      fac_view |> element("button[phx-value-score='-2']") |> render_click()
      assert_carousel_on_slide_4(fac_view)

      # Facilitator changes score
      fac_view |> element("[phx-click='edit_my_score']") |> render_click()
      fac_view |> element("button[phx-value-score='1']") |> render_click()
      assert_carousel_on_slide_4(fac_view)

      # Facilitator completes turn
      fac_view |> render_click("complete_turn")
      assert_carousel_on_slide_4(fac_view)

      # Alice's turn
      part_conn = Plug.Test.init_test_session(conn, %{browser_token: part_token})
      {:ok, part_view, _html} = live(part_conn, ~p"/session/#{session.code}")

      assert_carousel_on_slide_4(part_view)

      # Alice opens/closes criterion popup
      part_view |> render_click("show_criterion_info", %{"index" => "0"})
      assert_carousel_on_slide_4(part_view)

      part_view |> render_click("close_criterion_info")
      assert_carousel_on_slide_4(part_view)
    end

    test "sheet stack has stable element ID and data-slide attributes", %{
      conn: conn,
      session: session,
      fac_token: fac_token
    } do
      fac_conn = Plug.Test.init_test_session(conn, %{browser_token: fac_token})
      {:ok, view, _html} = live(fac_conn, ~p"/session/#{session.code}")

      html = render(view)

      # Verify stable ID exists on the stack element
      assert html =~ ~s(id="workshop-carousel")
      # Verify data-slide attributes on slides
      assert html =~ ~s(data-slide="0")
      assert html =~ ~s(data-slide="4")
      # Verify no Embla markup
      refute html =~ "embla__viewport"
      refute html =~ "embla__container"
    end
  end

  # Finds the position of the closing </div> that matches the element with the given id.
  # Uses a simple tag-depth counter starting from the element's opening tag.
  defp find_element_end(html, element_id) do
    case :binary.match(html, ~s(id="#{element_id}")) do
      {start, _} ->
        # Find the opening < before this id attribute
        # Find the start of the div, then count div opens/closes
        from_element = binary_part(html, start, byte_size(html) - start)
        find_matching_close(from_element, start)

      :nomatch ->
        nil
    end
  end

  # Count nested divs to find where this element's closing </div> is
  defp find_matching_close(html, base_offset) do
    # We start inside the opening tag. Find its closing >
    case :binary.match(html, ">") do
      {first_gt, _} ->
        rest = binary_part(html, first_gt + 1, byte_size(html) - first_gt - 1)
        do_find_close(rest, base_offset + first_gt + 1, 1)

      :nomatch ->
        nil
    end
  end

  defp do_find_close(_html, _offset, 0), do: nil

  defp do_find_close(html, offset, depth) when depth > 0 do
    open_div = :binary.match(html, "<div")
    close_div = :binary.match(html, "</div>")

    case {open_div, close_div} do
      {:nomatch, :nomatch} ->
        nil

      {:nomatch, {close_pos, close_len}} ->
        handle_close(html, offset, depth, close_pos, close_len)

      {_, {close_pos, close_len}} when open_div == :nomatch ->
        handle_close(html, offset, depth, close_pos, close_len)

      {{open_pos, _}, {close_pos, close_len}} when close_pos < open_pos ->
        handle_close(html, offset, depth, close_pos, close_len)

      {{open_pos, _}, _close_div} ->
        after_open = open_pos + 4
        rest = binary_part(html, after_open, byte_size(html) - after_open)
        do_find_close(rest, offset + after_open, depth + 1)
    end
  end

  defp handle_close(_html, offset, 1, close_pos, close_len) do
    offset + close_pos + close_len
  end

  defp handle_close(html, offset, depth, close_pos, close_len) do
    rest = binary_part(html, close_pos + close_len, byte_size(html) - close_pos - close_len)
    do_find_close(rest, offset + close_pos + close_len, depth - 1)
  end

  defp find_string_pos(html, search) do
    case :binary.match(html, search) do
      {pos, _} -> pos
      :nomatch -> nil
    end
  end
end
