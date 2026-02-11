defmodule WorkgroupPulse.Factory do
  @moduledoc """
  Test factory for building and inserting test data.

  Uses ExMachina for generating test fixtures.

  ## Usage

      # Build a struct without inserting
      build(:session)

      # Build with attributes
      build(:session, code: "ABC123")

      # Insert into database
      insert(:session)

      # Build params map for form testing
      params_for(:session)
  """

  use ExMachina.Ecto, repo: WorkgroupPulse.Repo

  alias WorkgroupPulse.Notes.{Action, Note}
  alias WorkgroupPulse.Scoring.Score
  alias WorkgroupPulse.Sessions.{Participant, Session}
  alias WorkgroupPulse.Workshops.{Question, Template}

  @doc """
  Generate a unique session code.
  """
  def unique_session_code do
    sequence(:session_code, fn n ->
      String.upcase(:crypto.strong_rand_bytes(3) |> Base.encode16()) <> "#{n}"
    end)
  end

  @doc """
  Generate a unique participant name.
  """
  def unique_participant_name do
    sequence(:participant_name, &"Participant #{&1}")
  end

  # Template factory
  def template_factory do
    %Template{
      name: sequence(:template_name, &"Workshop #{&1}"),
      slug: sequence(:template_slug, &"workshop-#{&1}"),
      description: "A test workshop for exploring team dynamics",
      version: "1.0.0",
      default_duration_minutes: 210
    }
  end

  # Question factory
  def question_factory do
    %Question{
      index: sequence(:question_index, & &1),
      title: sequence(:question_title, &"Question #{&1}"),
      criterion_number: sequence(:criterion_number, &"#{&1}"),
      criterion_name: "Test Criterion",
      explanation: "This is a test question explanation.",
      scale_type: "balance",
      scale_min: -5,
      scale_max: 5,
      optimal_value: 0,
      discussion_prompts: ["What do you think about this?", "Any surprises?"],
      scoring_guidance: "-5 = Low, 0 = Balanced, +5 = High",
      template: build(:template)
    }
  end

  def maximal_question_factory do
    struct!(
      question_factory(),
      %{
        scale_type: "maximal",
        scale_min: 0,
        scale_max: 10,
        optimal_value: nil,
        scoring_guidance: "0 = Low, 10 = High"
      }
    )
  end

  # Session factory
  def session_factory do
    %Session{
      code: unique_session_code(),
      state: "lobby",
      current_question_index: 0,
      last_activity_at: DateTime.utc_now() |> DateTime.truncate(:second),
      template: build(:template)
    }
  end

  def started_session_factory do
    struct!(
      session_factory(),
      %{
        state: "scoring",
        started_at: DateTime.utc_now() |> DateTime.truncate(:second),
        current_question_index: 0,
        current_turn_index: 0
      }
    )
  end

  def scoring_session_factory do
    struct!(
      session_factory(),
      %{
        state: "scoring",
        current_question_index: 0,
        started_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }
    )
  end

  # Participant factory
  def participant_factory do
    %Participant{
      name: unique_participant_name(),
      browser_token: Ecto.UUID.generate(),
      status: "active",
      is_ready: false,
      joined_at: DateTime.utc_now() |> DateTime.truncate(:second),
      last_seen_at: DateTime.utc_now() |> DateTime.truncate(:second),
      session: build(:session)
    }
  end

  # Score factory
  def score_factory do
    %Score{
      question_index: 0,
      value: 0,
      submitted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      session: build(:session),
      participant: build(:participant)
    }
  end

  # Note factory
  def note_factory do
    %Note{
      question_index: 0,
      content: sequence(:note_content, &"Discussion note #{&1}"),
      author_name: "Test Author",
      session: build(:session)
    }
  end

  # Action factory
  def action_factory do
    %Action{
      description: sequence(:action_description, &"Action item #{&1}"),
      owner_name: nil,
      completed: false,
      session: build(:session)
    }
  end
end
