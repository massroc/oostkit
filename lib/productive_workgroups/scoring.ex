defmodule ProductiveWorkgroups.Scoring do
  @moduledoc """
  The Scoring context.

  This context manages score submission, validation, aggregation,
  and traffic light color determination for workshop questions.

  ## Turn-Based Scoring

  Scores are now visible immediately when placed (butcher paper model).
  They lock progressively:
  - `turn_locked` - When participant clicks "Done" for their turn
  - `row_locked` - When the group advances to the next question
  """

  import Ecto.Query, warn: false

  alias ProductiveWorkgroups.Repo
  alias ProductiveWorkgroups.Scoring.Score
  alias ProductiveWorkgroups.Sessions.{Participant, Session}
  alias ProductiveWorkgroups.Timestamps
  alias ProductiveWorkgroups.Workshops
  alias ProductiveWorkgroups.Workshops.Template

  ## Score Submission

  @doc """
  Submits or updates a participant's score for a question.

  Validates the score value against the question's scale range.
  Returns `{:error, :score_locked}` if the score is already locked.

  In turn-based scoring, scores are visible immediately when placed.
  """
  def submit_score(%Session{} = session, %Participant{} = participant, question_index, value) do
    session = Repo.preload(session, :template)
    question = Workshops.get_question(session.template, question_index)

    attrs = %{
      question_index: question_index,
      value: value,
      submitted_at: Timestamps.now()
    }

    case get_score(session, participant, question_index) do
      nil ->
        %Score{}
        |> Score.submit_changeset(session, participant, attrs)
        |> Score.validate_value_range(question.scale_min, question.scale_max)
        |> Repo.insert()

      existing ->
        if Score.editable?(existing) do
          existing
          |> Score.update_changeset(attrs)
          |> Score.validate_value_range(question.scale_min, question.scale_max)
          |> Repo.update()
        else
          {:error, :score_locked}
        end
    end
  end

  @doc """
  Gets a participant's score for a specific question.
  """
  def get_score(%Session{} = session, %Participant{} = participant, question_index) do
    Repo.get_by(Score,
      session_id: session.id,
      participant_id: participant.id,
      question_index: question_index
    )
  end

  @doc """
  Lists all scores for a question in a session.
  """
  def list_scores_for_question(%Session{} = session, question_index) do
    Score
    |> where([s], s.session_id == ^session.id and s.question_index == ^question_index)
    |> Repo.all()
  end

  @doc """
  Counts the number of scores submitted for a question.
  """
  def count_scores(%Session{} = session, question_index) do
    Score
    |> where([s], s.session_id == ^session.id and s.question_index == ^question_index)
    |> Repo.aggregate(:count)
  end

  ## Turn-Based Score Locking

  @doc """
  Locks a participant's turn for a question.

  Called when a participant clicks "Done" - they can no longer edit their score
  for this question, but the row is not yet permanently locked.
  """
  def lock_participant_turn(%Session{} = session, %Participant{} = participant, question_index) do
    case get_score(session, participant, question_index) do
      nil ->
        {:error, :no_score}

      score ->
        score
        |> Score.lock_turn_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Locks all scores for a question (row) permanently.

  Called when the group advances to the next question. After this,
  scores for this question can never be edited.
  """
  def lock_row(%Session{} = session, question_index) do
    Score
    |> where([s], s.session_id == ^session.id and s.question_index == ^question_index)
    |> Repo.update_all(set: [row_locked: true, turn_locked: true])

    :ok
  end

  @doc """
  Checks if a score can be edited.

  A score can be edited if:
  - It exists
  - turn_locked is false
  - row_locked is false
  """
  def can_edit_score?(%Session{} = session, %Participant{} = participant, question_index) do
    case get_score(session, participant, question_index) do
      nil -> false
      score -> Score.editable?(score)
    end
  end

  @doc """
  Checks if a row (question) is locked.
  """
  def row_locked?(%Session{} = session, question_index) do
    Score
    |> where([s], s.session_id == ^session.id and s.question_index == ^question_index)
    |> where([s], s.row_locked == true)
    |> Repo.exists?()
  end

  @doc """
  Checks if all active non-observer participants have submitted scores for a question.
  """
  def all_scored?(%Session{} = session, question_index) do
    active_count =
      Participant
      |> where(
        [p],
        p.session_id == ^session.id and p.status == "active" and p.is_observer == false
      )
      |> Repo.aggregate(:count)

    score_count = count_scores(session, question_index)

    active_count > 0 and active_count == score_count
  end

  ## Score Aggregation

  @doc """
  Calculates the average score for a question.
  """
  def calculate_average(%Session{} = session, question_index) do
    result =
      Score
      |> where([s], s.session_id == ^session.id and s.question_index == ^question_index)
      |> select([s], avg(s.value))
      |> Repo.one()

    case result do
      nil -> nil
      avg -> Float.round(Decimal.to_float(avg), 1)
    end
  end

  @doc """
  Calculates the spread (min, max) of scores for a question.
  """
  def calculate_spread(%Session{} = session, question_index) do
    result =
      Score
      |> where([s], s.session_id == ^session.id and s.question_index == ^question_index)
      |> select([s], {min(s.value), max(s.value)})
      |> Repo.one()

    case result do
      {nil, nil} -> nil
      spread -> spread
    end
  end

  @doc """
  Gets a comprehensive summary of scores for a question.

  Returns a map with:
  - `:count` - Number of scores
  - `:average` - Mean score
  - `:min` - Minimum score
  - `:max` - Maximum score
  - `:spread` - Difference between max and min
  """
  def get_score_summary(%Session{} = session, question_index) do
    session
    |> list_scores_for_question(question_index)
    |> calculate_summary_from_scores()
  end

  @doc """
  Gets score summaries for all questions in a session.

  Optimized to load all scores in a single query instead of N+1 queries.
  """
  def get_all_scores_summary(%Session{} = session, %Template{} = template) do
    questions = Workshops.list_questions(template)

    # Single query to get all scores for this session, grouped by question_index
    all_scores =
      Score
      |> where([s], s.session_id == ^session.id)
      |> Repo.all()
      |> Enum.group_by(& &1.question_index)

    Enum.map(questions, fn question ->
      scores = Map.get(all_scores, question.index, [])
      summary = calculate_summary_from_scores(scores)

      combined_value =
        calculate_combined_team_value(scores, question.scale_type, question.optimal_value)

      Map.merge(summary, %{
        question_index: question.index,
        title: question.title,
        scale_type: question.scale_type,
        optimal_value: question.optimal_value,
        # Use combined_team_value for consistent color logic across both scale types
        # This treats the 0-10 combined value with maximal scale thresholds
        color:
          if(combined_value,
            do: traffic_light_color("maximal", combined_value, nil),
            else: nil
          ),
        combined_team_value: combined_value
      })
    end)
  end

  # Calculate summary stats from a list of scores (no database query)
  defp calculate_summary_from_scores([]) do
    %{count: 0, average: nil, min: nil, max: nil, spread: nil}
  end

  defp calculate_summary_from_scores(scores) do
    values = Enum.map(scores, & &1.value)

    %{
      count: length(values),
      average: Float.round(Enum.sum(values) / length(values), 1),
      min: Enum.min(values),
      max: Enum.max(values),
      spread: Enum.max(values) - Enum.min(values)
    }
  end

  ## Traffic Light Colors

  @doc """
  Determines the traffic light color for a score.

  ## Balance Scale (optimal at 0)
  - Green: within ±1 of optimal (0)
  - Amber: within ±2-3 of optimal
  - Red: ±4-5 from optimal

  ## Maximal Scale (more is better, 0-10)
  - Green: 7-10
  - Amber: 4-6
  - Red: 0-3
  """
  def traffic_light_color("balance", value, optimal_value) do
    deviation = abs(value - (optimal_value || 0))

    cond do
      deviation <= 1 -> :green
      deviation <= 3 -> :amber
      true -> :red
    end
  end

  def traffic_light_color("maximal", value, _optimal_value) do
    cond do
      value >= 7 -> :green
      value >= 4 -> :amber
      true -> :red
    end
  end

  @doc """
  Converts a traffic light color to grade points.

  - Green: 2 points (good)
  - Amber: 1 point (medium)
  - Red: 0 points (low)
  """
  def color_to_grade(:green), do: 2
  def color_to_grade(:amber), do: 1
  def color_to_grade(:red), do: 0
  def color_to_grade(_), do: 0

  @doc """
  Calculates the Combined Team Value for a question.

  For balance scale (-5 to 5), converts each score to points based on distance from optimal (0):
  - 0 = 10 points, ±1 = 8 points, ±2 = 6 points, ±3 = 4 points, ±4 = 2 points, ±5 = 0 points

  For maximal scale (0-10), uses the actual score values directly.

  Returns the average across all participants.
  """
  def calculate_combined_team_value([], _scale_type, _optimal_value), do: nil

  def calculate_combined_team_value(scores, "balance", _optimal_value) do
    points =
      Enum.map(scores, fn score ->
        # 0 = 10pts, ±1 = 8pts, ±2 = 6pts, ±3 = 4pts, ±4 = 2pts, ±5 = 0pts
        max(0, 10 - abs(score.value) * 2)
      end)

    Float.round(Enum.sum(points) / length(points), 1)
  end

  def calculate_combined_team_value(scores, "maximal", _optimal_value) do
    # For maximal scale, just average the actual values (already 0-10)
    values = Enum.map(scores, & &1.value)
    Float.round(Enum.sum(values) / length(values), 1)
  end

  def calculate_combined_team_value(scores, _scale_type, _optimal_value) do
    # Default: average the values
    values = Enum.map(scores, & &1.value)
    Float.round(Enum.sum(values) / length(values), 1)
  end

  @doc """
  Gets all individual scores for a session, organized by question index.

  Returns a map where keys are question indices and values are lists of scores
  with participant information, ordered by participant's `joined_at` timestamp.

  Each score entry includes:
  - `:value` - The score value
  - `:participant_id` - The participant's ID
  - `:participant_name` - The participant's name
  - `:color` - The traffic light color for the score

  ## Parameters
  - `session` - The session to get scores for
  - `participants` - List of participants (already ordered by joined_at)
  - `template` - The workshop template with questions

  ## Example

      iex> get_all_individual_scores(session, participants, template)
      %{
        0 => [
          %{value: 3, participant_id: "...", participant_name: "Alice", color: :amber},
          %{value: -1, participant_id: "...", participant_name: "Bob", color: :green}
        ],
        1 => [...]
      }
  """
  def get_all_individual_scores(%Session{} = session, participants, %Template{} = template) do
    questions = Workshops.list_questions(template)

    # Build order map: participant_id => order_index (for sorting by arrival order)
    participant_order =
      participants
      |> Enum.with_index()
      |> Map.new(fn {p, idx} -> {p.id, idx} end)

    # Build participant name map for O(1) lookups
    participant_names = Map.new(participants, &{&1.id, &1.name})

    # Single query to get all scores for this session
    all_scores =
      Score
      |> where([s], s.session_id == ^session.id)
      |> Repo.all()
      |> Enum.group_by(& &1.question_index)

    # Build question map for color calculations (used below in the mapping)

    # Process each question
    Map.new(questions, fn question ->
      scores = Map.get(all_scores, question.index, [])

      ordered_scores =
        scores
        |> Enum.map(fn score ->
          %{
            value: score.value,
            participant_id: score.participant_id,
            participant_name: Map.get(participant_names, score.participant_id, "Unknown"),
            color: traffic_light_color(question.scale_type, score.value, question.optimal_value)
          }
        end)
        |> Enum.sort_by(fn s -> Map.get(participant_order, s.participant_id, 999) end)

      {question.index, ordered_scores}
    end)
  end
end
