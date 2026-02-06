defmodule WorkgroupPulse.ScoringTest do
  use WorkgroupPulse.DataCase, async: true

  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Scoring
  alias WorkgroupPulse.Scoring.Score
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulse.Workshops
  alias WorkgroupPulse.Workshops.{Question, Template}

  describe "scores" do
    setup do
      slug = "test-scoring-workshop-#{System.unique_integer([:positive])}"

      template =
        Repo.insert!(%Template{
          name: "Test Workshop",
          slug: slug,
          version: "1.0.0",
          default_duration_minutes: 180
        })

      # Create balance scale question (Q1: -5 to 5, optimal 0)
      Repo.insert!(%Question{
        template_id: template.id,
        index: 0,
        title: "Elbow Room",
        criterion_number: "1",
        criterion_name: "Autonomy",
        explanation: "Test",
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        optimal_value: 0
      })

      # Create maximal scale question (Q2: 0 to 10, more is better)
      Repo.insert!(%Question{
        template_id: template.id,
        index: 1,
        title: "Mutual Support",
        criterion_number: "4",
        criterion_name: "Support",
        explanation: "Test",
        scale_type: "maximal",
        scale_min: 0,
        scale_max: 10,
        optimal_value: nil
      })

      {:ok, session} = Sessions.create_session(template)
      {:ok, participant} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())

      %{session: session, participant: participant, template: template}
    end

    test "submit_score/4 creates a score", %{session: session, participant: participant} do
      assert {:ok, %Score{} = score} = Scoring.submit_score(session, participant, 0, 3)
      assert score.value == 3
      assert score.question_index == 0
      assert score.participant_id == participant.id
      assert score.session_id == session.id
      assert score.submitted_at != nil
    end

    test "submit_score/4 updates existing score", %{session: session, participant: participant} do
      {:ok, score1} = Scoring.submit_score(session, participant, 0, 3)
      {:ok, score2} = Scoring.submit_score(session, participant, 0, -2)

      assert score1.id == score2.id
      assert score2.value == -2
    end

    test "submit_score/4 validates balance scale range", %{
      session: session,
      participant: participant
    } do
      # Balance scale Q1 is -5 to 5
      assert {:ok, _} = Scoring.submit_score(session, participant, 0, -5)
      assert {:ok, _} = Scoring.submit_score(session, participant, 0, 5)
      assert {:error, changeset} = Scoring.submit_score(session, participant, 0, -6)
      assert "must be between -5 and 5" in errors_on(changeset).value
      assert {:error, changeset} = Scoring.submit_score(session, participant, 0, 6)
      assert "must be between -5 and 5" in errors_on(changeset).value
    end

    test "submit_score/4 validates maximal scale range", %{
      session: session,
      participant: participant
    } do
      # Maximal scale Q2 is 0 to 10
      assert {:ok, _} = Scoring.submit_score(session, participant, 1, 0)
      assert {:ok, _} = Scoring.submit_score(session, participant, 1, 10)
      assert {:error, changeset} = Scoring.submit_score(session, participant, 1, -1)
      assert "must be between 0 and 10" in errors_on(changeset).value
      assert {:error, changeset} = Scoring.submit_score(session, participant, 1, 11)
      assert "must be between 0 and 10" in errors_on(changeset).value
    end

    test "get_score/3 retrieves a score", %{session: session, participant: participant} do
      {:ok, score} = Scoring.submit_score(session, participant, 0, 3)
      assert Scoring.get_score(session, participant, 0).id == score.id
    end

    test "get_score/3 returns nil when not found", %{session: session, participant: participant} do
      assert Scoring.get_score(session, participant, 99) == nil
    end

    test "list_scores_for_question/2 returns all scores", %{
      session: session,
      participant: participant
    } do
      {:ok, p2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())

      {:ok, _} = Scoring.submit_score(session, participant, 0, 3)
      {:ok, _} = Scoring.submit_score(session, p2, 0, -1)

      scores = Scoring.list_scores_for_question(session, 0)
      assert length(scores) == 2
    end

    test "all_scored?/2 checks if all active participants scored", %{
      session: session,
      participant: participant
    } do
      {:ok, p2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())

      refute Scoring.all_scored?(session, 0)

      {:ok, _} = Scoring.submit_score(session, participant, 0, 3)
      refute Scoring.all_scored?(session, 0)

      {:ok, _} = Scoring.submit_score(session, p2, 0, -1)
      assert Scoring.all_scored?(session, 0)
    end

    test "count_scores/2 returns score count", %{session: session, participant: participant} do
      assert Scoring.count_scores(session, 0) == 0

      {:ok, _} = Scoring.submit_score(session, participant, 0, 3)
      assert Scoring.count_scores(session, 0) == 1
    end
  end

  describe "score aggregation" do
    setup do
      slug = "test-aggregation-#{System.unique_integer([:positive])}"

      template =
        Repo.insert!(%Template{
          name: "Aggregation Workshop",
          slug: slug,
          version: "1.0.0",
          default_duration_minutes: 180
        })

      Repo.insert!(%Question{
        template_id: template.id,
        index: 0,
        title: "Q1",
        criterion_number: "1",
        criterion_name: "C1",
        explanation: "Test",
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        optimal_value: 0
      })

      {:ok, session} = Sessions.create_session(template)
      {:ok, p1} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      {:ok, p2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())
      {:ok, p3} = Sessions.join_session(session, "Carol", Ecto.UUID.generate())

      %{session: session, participants: [p1, p2, p3]}
    end

    test "calculate_average/2 computes mean score", %{
      session: session,
      participants: [p1, p2, p3]
    } do
      {:ok, _} = Scoring.submit_score(session, p1, 0, 3)
      {:ok, _} = Scoring.submit_score(session, p2, 0, 0)
      {:ok, _} = Scoring.submit_score(session, p3, 0, -3)

      assert Scoring.calculate_average(session, 0) == 0.0
    end

    test "calculate_average/2 returns nil when no scores", %{session: session} do
      assert Scoring.calculate_average(session, 0) == nil
    end

    test "calculate_spread/2 computes min and max", %{
      session: session,
      participants: [p1, p2, p3]
    } do
      {:ok, _} = Scoring.submit_score(session, p1, 0, 3)
      {:ok, _} = Scoring.submit_score(session, p2, 0, 0)
      {:ok, _} = Scoring.submit_score(session, p3, 0, -3)

      assert Scoring.calculate_spread(session, 0) == {-3, 3}
    end

    test "calculate_spread/2 returns nil when no scores", %{session: session} do
      assert Scoring.calculate_spread(session, 0) == nil
    end

    test "get_score_summary/2 returns comprehensive summary", %{
      session: session,
      participants: [p1, p2, p3]
    } do
      {:ok, _} = Scoring.submit_score(session, p1, 0, 4)
      {:ok, _} = Scoring.submit_score(session, p2, 0, 2)
      {:ok, _} = Scoring.submit_score(session, p3, 0, 0)

      summary = Scoring.get_score_summary(session, 0)

      assert summary.count == 3
      assert summary.average == 2.0
      assert summary.min == 0
      assert summary.max == 4
      assert summary.spread == 4
    end
  end

  describe "traffic light colors" do
    test "balance scale - green for optimal range (±0-1)" do
      assert Scoring.traffic_light_color("balance", 0, 0) == :green
      assert Scoring.traffic_light_color("balance", 1, 0) == :green
      assert Scoring.traffic_light_color("balance", -1, 0) == :green
    end

    test "balance scale - amber for moderate deviation (±2-3)" do
      assert Scoring.traffic_light_color("balance", 2, 0) == :amber
      assert Scoring.traffic_light_color("balance", -2, 0) == :amber
      assert Scoring.traffic_light_color("balance", 3, 0) == :amber
      assert Scoring.traffic_light_color("balance", -3, 0) == :amber
    end

    test "balance scale - red for high deviation (±4-5)" do
      assert Scoring.traffic_light_color("balance", 4, 0) == :red
      assert Scoring.traffic_light_color("balance", -4, 0) == :red
      assert Scoring.traffic_light_color("balance", 5, 0) == :red
      assert Scoring.traffic_light_color("balance", -5, 0) == :red
    end

    test "maximal scale - green for high scores (7-10)" do
      assert Scoring.traffic_light_color("maximal", 7, nil) == :green
      assert Scoring.traffic_light_color("maximal", 8, nil) == :green
      assert Scoring.traffic_light_color("maximal", 9, nil) == :green
      assert Scoring.traffic_light_color("maximal", 10, nil) == :green
    end

    test "maximal scale - amber for medium scores (4-6)" do
      assert Scoring.traffic_light_color("maximal", 4, nil) == :amber
      assert Scoring.traffic_light_color("maximal", 5, nil) == :amber
      assert Scoring.traffic_light_color("maximal", 6, nil) == :amber
    end

    test "maximal scale - red for low scores (0-3)" do
      assert Scoring.traffic_light_color("maximal", 0, nil) == :red
      assert Scoring.traffic_light_color("maximal", 1, nil) == :red
      assert Scoring.traffic_light_color("maximal", 2, nil) == :red
      assert Scoring.traffic_light_color("maximal", 3, nil) == :red
    end
  end

  describe "color_to_grade/1" do
    test "converts green to 2 points" do
      assert Scoring.color_to_grade(:green) == 2
    end

    test "converts amber to 1 point" do
      assert Scoring.color_to_grade(:amber) == 1
    end

    test "converts red to 0 points" do
      assert Scoring.color_to_grade(:red) == 0
    end

    test "converts nil to 0 points" do
      assert Scoring.color_to_grade(nil) == 0
    end
  end

  describe "calculate_combined_team_value/3" do
    test "returns nil for empty scores" do
      assert Scoring.calculate_combined_team_value([], "balance", 0) == nil
    end

    test "returns 10 when everyone scores optimal on balance scale" do
      # All scores at 0 -> all 10 points -> avg 10
      scores = [%{value: 0}, %{value: 0}, %{value: 0}]
      assert Scoring.calculate_combined_team_value(scores, "balance", 0) == 10.0
    end

    test "returns 0 when everyone scores worst on balance scale" do
      # All scores at ±5 -> all 0 points -> avg 0
      scores = [%{value: 5}, %{value: -5}, %{value: 5}]
      assert Scoring.calculate_combined_team_value(scores, "balance", 0) == 0.0
    end

    test "calculates points correctly for balance scale" do
      # 0=10pts, ±1=8pts, ±2=6pts, ±3=4pts, ±4=2pts, ±5=0pts
      # scores: [0, -2, 3] -> points: [10, 6, 4] -> avg: 20/3 = 6.7
      scores = [%{value: 0}, %{value: -2}, %{value: 3}]
      assert Scoring.calculate_combined_team_value(scores, "balance", 0) == 6.7
    end

    test "calculates mixed scores correctly on balance scale" do
      # scores: [0, 2, 5] -> points: [10, 6, 0] -> avg: 16/3 = 5.3
      scores = [%{value: 0}, %{value: 2}, %{value: 5}]
      assert Scoring.calculate_combined_team_value(scores, "balance", 0) == 5.3
    end

    test "averages actual values on maximal scale" do
      # scores: [10, 8, 6] -> avg: 24/3 = 8.0
      scores = [%{value: 10}, %{value: 8}, %{value: 6}]
      assert Scoring.calculate_combined_team_value(scores, "maximal", nil) == 8.0
    end

    test "returns low average for low maximal scores" do
      # scores: [0, 2, 4] -> avg: 6/3 = 2.0
      scores = [%{value: 0}, %{value: 2}, %{value: 4}]
      assert Scoring.calculate_combined_team_value(scores, "maximal", nil) == 2.0
    end

    test "calculates mixed scores correctly on maximal scale" do
      # scores: [10, 5, 0] -> avg: 15/3 = 5.0
      scores = [%{value: 10}, %{value: 5}, %{value: 0}]
      assert Scoring.calculate_combined_team_value(scores, "maximal", nil) == 5.0
    end
  end

  describe "session score summary" do
    setup do
      slug = "test-summary-#{System.unique_integer([:positive])}"

      template =
        Repo.insert!(%Template{
          name: "Summary Workshop",
          slug: slug,
          version: "1.0.0",
          default_duration_minutes: 180
        })

      criterion_numbers = ["1", "2a", "2b", "3", "4", "5a", "5b", "6"]

      for i <- 0..7 do
        scale_type = if i < 4, do: "balance", else: "maximal"
        scale_min = if i < 4, do: -5, else: 0
        scale_max = if i < 4, do: 5, else: 10
        optimal = if i < 4, do: 0, else: nil

        Repo.insert!(%Question{
          template_id: template.id,
          index: i,
          title: "Q#{i + 1}",
          criterion_number: Enum.at(criterion_numbers, i),
          criterion_name: "C#{i + 1}",
          explanation: "Test",
          scale_type: scale_type,
          scale_min: scale_min,
          scale_max: scale_max,
          optimal_value: optimal
        })
      end

      {:ok, session} = Sessions.create_session(template)
      {:ok, participant} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())

      %{session: session, participant: participant, template: template}
    end

    test "get_all_scores_summary/1 returns summaries for all questions", %{
      session: session,
      participant: participant,
      template: template
    } do
      # Submit scores for all 8 questions
      for i <- 0..7 do
        value = if i < 4, do: Enum.random(-5..5), else: Enum.random(0..10)
        Scoring.submit_score(session, participant, i, value)
      end

      summaries = Scoring.get_all_scores_summary(session, template)

      assert length(summaries) == 8
      assert Enum.all?(summaries, fn s -> s.count == 1 end)
    end

    test "get_all_scores_summary/1 includes combined_team_value for each question", %{
      session: session,
      template: template
    } do
      # Create multiple participants with varying scores (use different names from setup's Alice)
      {:ok, p1} = Sessions.join_session(session, "Dave", Ecto.UUID.generate())
      {:ok, p2} = Sessions.join_session(session, "Eve", Ecto.UUID.generate())
      {:ok, p3} = Sessions.join_session(session, "Frank", Ecto.UUID.generate())

      # Submit scores for first balance question (optimal at 0)
      # Dave: 0 -> 10pts, Eve: 2 -> 6pts, Frank: 5 -> 0pts
      # Total: 16, avg = 16/3 = 5.3
      Scoring.submit_score(session, p1, 0, 0)
      Scoring.submit_score(session, p2, 0, 2)
      Scoring.submit_score(session, p3, 0, 5)

      summaries = Scoring.get_all_scores_summary(session, template)
      first_summary = Enum.find(summaries, fn s -> s.question_index == 0 end)

      assert first_summary.combined_team_value == 5.3
      assert first_summary.average != nil
      assert first_summary.color != nil
    end
  end

  describe "get_all_individual_scores/3" do
    setup do
      slug = "test-individual-scores-#{System.unique_integer([:positive])}"

      template =
        Repo.insert!(%Template{
          name: "Individual Scores Workshop",
          slug: slug,
          version: "1.0.0",
          default_duration_minutes: 180
        })

      # Create a balance scale question
      Repo.insert!(%Question{
        template_id: template.id,
        index: 0,
        title: "Q1 Balance",
        criterion_number: "1",
        criterion_name: "Autonomy",
        explanation: "Test",
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        optimal_value: 0
      })

      # Create a maximal scale question
      Repo.insert!(%Question{
        template_id: template.id,
        index: 1,
        title: "Q2 Maximal",
        criterion_number: "2",
        criterion_name: "Learning",
        explanation: "Test",
        scale_type: "maximal",
        scale_min: 0,
        scale_max: 10,
        optimal_value: nil
      })

      {:ok, session} = Sessions.create_session(template)

      # Join participants in specific order (Alice first, Bob second, Carol third)
      {:ok, p1} = Sessions.join_session(session, "Alice", Ecto.UUID.generate())
      # Add a small delay to ensure different joined_at timestamps
      Process.sleep(10)
      {:ok, p2} = Sessions.join_session(session, "Bob", Ecto.UUID.generate())
      Process.sleep(10)
      {:ok, p3} = Sessions.join_session(session, "Carol", Ecto.UUID.generate())

      # Reload template with questions
      template = Workshops.get_template_with_questions(template.id)

      %{
        session: session,
        participants: [p1, p2, p3],
        template: template
      }
    end

    test "returns scores grouped by question index", %{
      session: session,
      participants: [p1, p2, p3],
      template: template
    } do
      # Submit scores for question 0
      {:ok, _} = Scoring.submit_score(session, p1, 0, 2)
      {:ok, _} = Scoring.submit_score(session, p2, 0, -1)
      {:ok, _} = Scoring.submit_score(session, p3, 0, 0)

      # Submit scores for question 1
      {:ok, _} = Scoring.submit_score(session, p1, 1, 8)
      {:ok, _} = Scoring.submit_score(session, p2, 1, 5)

      participants = Sessions.list_participants(session)
      result = Scoring.get_all_individual_scores(session, participants, template)

      # Should have entries for both questions
      assert Map.has_key?(result, 0)
      assert Map.has_key?(result, 1)

      # Question 0 should have 3 scores
      assert length(result[0]) == 3
      # Question 1 should have 2 scores
      assert length(result[1]) == 2
    end

    test "orders scores by participant joined_at", %{
      session: session,
      participants: [p1, p2, p3],
      template: template
    } do
      # Submit scores in reverse order (Carol, Bob, Alice)
      {:ok, _} = Scoring.submit_score(session, p3, 0, 0)
      {:ok, _} = Scoring.submit_score(session, p2, 0, -1)
      {:ok, _} = Scoring.submit_score(session, p1, 0, 2)

      participants = Sessions.list_participants(session)
      result = Scoring.get_all_individual_scores(session, participants, template)

      # Scores should be ordered by joined_at (Alice, Bob, Carol)
      [first, second, third] = result[0]
      assert first.participant_name == "Alice"
      assert second.participant_name == "Bob"
      assert third.participant_name == "Carol"
    end

    test "includes correct score values and colors", %{
      session: session,
      participants: [p1, p2, _p3],
      template: template
    } do
      # Balance scale: 2 is amber, -1 is green
      {:ok, _} = Scoring.submit_score(session, p1, 0, 2)
      {:ok, _} = Scoring.submit_score(session, p2, 0, -1)

      # Maximal scale: 8 is green, 3 is red
      {:ok, _} = Scoring.submit_score(session, p1, 1, 8)
      {:ok, _} = Scoring.submit_score(session, p2, 1, 3)

      participants = Sessions.list_participants(session)
      result = Scoring.get_all_individual_scores(session, participants, template)

      # Check balance scale colors
      [alice_q0, bob_q0] = result[0]
      assert alice_q0.value == 2
      assert alice_q0.color == :amber
      assert bob_q0.value == -1
      assert bob_q0.color == :green

      # Check maximal scale colors
      [alice_q1, bob_q1] = result[1]
      assert alice_q1.value == 8
      assert alice_q1.color == :green
      assert bob_q1.value == 3
      assert bob_q1.color == :red
    end

    test "returns empty lists for questions without scores", %{
      session: session,
      participants: _participants,
      template: template
    } do
      participants = Sessions.list_participants(session)
      result = Scoring.get_all_individual_scores(session, participants, template)

      # Both questions should have empty lists
      assert result[0] == []
      assert result[1] == []
    end

    test "includes participant_id in each score entry", %{
      session: session,
      participants: [p1, _p2, _p3],
      template: template
    } do
      {:ok, _} = Scoring.submit_score(session, p1, 0, 3)

      participants = Sessions.list_participants(session)
      result = Scoring.get_all_individual_scores(session, participants, template)

      [score] = result[0]
      assert score.participant_id == p1.id
      assert score.participant_name == "Alice"
    end
  end
end
