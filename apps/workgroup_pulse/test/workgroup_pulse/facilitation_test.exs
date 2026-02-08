defmodule WorkgroupPulse.FacilitationTest do
  use WorkgroupPulse.DataCase, async: true

  alias WorkgroupPulse.Facilitation

  describe "phase management" do
    test "phase_name/1 returns descriptive phase names" do
      assert Facilitation.phase_name("question_0") == "Question 1"
      assert Facilitation.phase_name("question_7") == "Question 8"
      assert Facilitation.phase_name("summary") == "Summary"
      assert Facilitation.phase_name("summary_actions") == "Summary + Actions"
      assert Facilitation.phase_name("unknown") == "unknown"
    end

    test "suggested_duration/1 returns default durations in seconds" do
      # 15 minutes per question
      assert Facilitation.suggested_duration("question_0") == 900
      # 10 minutes
      assert Facilitation.suggested_duration("summary") == 600
      # 5 minutes default
      assert Facilitation.suggested_duration("unknown") == 300
    end
  end

  describe "segment-based timer functions" do
    test "calculate_segment_duration/1 returns nil for nil duration" do
      session = %WorkgroupPulse.Sessions.Session{planned_duration_minutes: nil}
      assert Facilitation.calculate_segment_duration(session) == nil
    end

    test "calculate_segment_duration/1 calculates correctly for 100 minute session" do
      session = %WorkgroupPulse.Sessions.Session{planned_duration_minutes: 100}
      # 100 minutes = 6000 seconds, divided by 10 segments = 600 seconds per segment
      assert Facilitation.calculate_segment_duration(session) == 600
    end

    test "calculate_segment_duration/1 calculates correctly for 90 minute session" do
      session = %WorkgroupPulse.Sessions.Session{planned_duration_minutes: 90}
      # 90 minutes = 5400 seconds, divided by 10 segments = 540 seconds per segment
      assert Facilitation.calculate_segment_duration(session) == 540
    end

    test "current_timer_phase/1 returns correct phase for scoring state" do
      session = %WorkgroupPulse.Sessions.Session{
        state: "scoring",
        current_question_index: 0
      }

      assert Facilitation.current_timer_phase(session) == "question_0"

      session = %WorkgroupPulse.Sessions.Session{
        state: "scoring",
        current_question_index: 5
      }

      assert Facilitation.current_timer_phase(session) == "question_5"

      session = %WorkgroupPulse.Sessions.Session{
        state: "scoring",
        current_question_index: 7
      }

      assert Facilitation.current_timer_phase(session) == "question_7"
    end

    test "current_timer_phase/1 returns summary_actions for summary state" do
      session = %WorkgroupPulse.Sessions.Session{
        state: "summary",
        current_question_index: 7
      }

      assert Facilitation.current_timer_phase(session) == "summary_actions"
    end

    test "current_timer_phase/1 returns nil for non-timed states" do
      assert Facilitation.current_timer_phase(%WorkgroupPulse.Sessions.Session{
               state: "lobby",
               current_question_index: 0
             }) == nil

      assert Facilitation.current_timer_phase(%WorkgroupPulse.Sessions.Session{
               state: "completed",
               current_question_index: 7
             }) == nil
    end

    test "timer_enabled?/1 returns false for nil duration" do
      session = %WorkgroupPulse.Sessions.Session{
        planned_duration_minutes: nil,
        state: "scoring"
      }

      assert Facilitation.timer_enabled?(session) == false
    end

    test "timer_enabled?/1 returns false for non-timed states" do
      assert Facilitation.timer_enabled?(%WorkgroupPulse.Sessions.Session{
               planned_duration_minutes: 100,
               state: "lobby"
             }) == false

      assert Facilitation.timer_enabled?(%WorkgroupPulse.Sessions.Session{
               planned_duration_minutes: 100,
               state: "completed"
             }) == false
    end

    test "timer_enabled?/1 returns true for timed states with duration" do
      assert Facilitation.timer_enabled?(%WorkgroupPulse.Sessions.Session{
               planned_duration_minutes: 100,
               state: "scoring"
             }) == true

      assert Facilitation.timer_enabled?(%WorkgroupPulse.Sessions.Session{
               planned_duration_minutes: 100,
               state: "summary"
             }) == true
    end

    test "warning_threshold/1 returns 10% of segment duration" do
      session = %WorkgroupPulse.Sessions.Session{planned_duration_minutes: 100}
      # 600 seconds per segment, 10% = 60 seconds
      assert Facilitation.warning_threshold(session) == 60
    end

    test "warning_threshold/1 returns nil for nil duration" do
      session = %WorkgroupPulse.Sessions.Session{planned_duration_minutes: nil}
      assert Facilitation.warning_threshold(session) == nil
    end
  end
end
