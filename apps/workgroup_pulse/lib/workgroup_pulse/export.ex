defmodule WorkgroupPulse.Export do
  @moduledoc """
  Handles exporting workshop data to CSV.

  Two report types:
  - `:full` — Full Workshop Report with all data including individual scores,
    participant names, notes, and actions
  - `:team` — Team Report with anonymized team-level data: team scores,
    strengths/concerns, and actions (no individual scores, names, or notes)
  """

  alias WorkgroupPulse.Notes
  alias WorkgroupPulse.Scoring
  alias WorkgroupPulse.Sessions
  alias WorkgroupPulse.Sessions.Session

  @doc """
  Exports workshop data as CSV.

  ## Options
  - `:content` - Report type: `:full` or `:team` (default: `:full`)

  Returns `{:ok, {filename, content_type, data}}` or `{:error, reason}`
  """
  def export(%Session{} = session, opts \\ []) do
    content = Keyword.get(opts, :content, :full)

    session = Sessions.get_session_with_all(session.id)
    template = session.template
    participants = Sessions.list_participants(session)
    scores_summary = Scoring.get_all_scores_summary(session, template)
    individual_scores = Scoring.get_all_individual_scores(session, participants, template)
    notes = Notes.list_all_notes(session)
    actions = Notes.list_all_actions(session)

    data = %{
      session: session,
      template: template,
      participants: participants,
      scores_summary: scores_summary,
      individual_scores: individual_scores,
      notes: notes,
      actions: actions
    }

    export_csv(data, content, session.code)
  end

  defp export_csv(data, content, code) do
    csv_content =
      case content do
        :full -> build_full_csv(data)
        :team -> build_team_csv(data)
      end

    filename = "workshop_#{code}_#{content}_report.csv"
    {:ok, {filename, "text/csv", csv_content}}
  end

  defp build_full_csv(data) do
    session_section = build_session_info_csv(data.session)
    participants_section = build_participants_csv(data.participants)

    scores_section =
      build_scores_csv(data.scores_summary, data.individual_scores, data.participants)

    notes_section = build_notes_csv(data.notes)
    actions_section = build_actions_csv(data.actions, :full)

    Enum.join(
      [session_section, participants_section, scores_section, notes_section, actions_section],
      "\n\n"
    )
  end

  defp build_team_csv(data) do
    session_section = build_session_info_csv(data.session)
    team_scores_section = build_team_scores_csv(data.scores_summary)
    strengths_concerns_section = build_strengths_concerns_csv(data.scores_summary)
    actions_section = build_actions_csv(data.actions, :team)

    Enum.join(
      [
        "TEAM REPORT\nNo individual scores, names or notes",
        session_section,
        team_scores_section,
        strengths_concerns_section,
        actions_section
      ],
      "\n\n"
    )
  end

  defp build_session_info_csv(session) do
    started = format_datetime(session.started_at)
    completed = format_datetime(session.completed_at)

    """
    SESSION INFORMATION
    Session Code,#{session.code}
    Started,#{started}
    Completed,#{completed}
    """
    |> String.trim()
  end

  defp build_participants_csv(participants) do
    header = "PARTICIPANTS\nName,Role,Status"
    rows = Enum.map_join(participants, "\n", &format_participant_row/1)
    header <> "\n" <> rows
  end

  defp format_participant_row(p) do
    role = participant_role(p)
    "#{csv_escape(p.name)},#{role},#{p.status}"
  end

  defp participant_role(%{is_facilitator: true}), do: "Facilitator"
  defp participant_role(%{is_observer: true}), do: "Observer"
  defp participant_role(_), do: "Participant"

  defp build_scores_csv(scores_summary, individual_scores, participants) do
    team_section = build_team_scores_csv(scores_summary)

    individual_section =
      build_individual_scores_csv(scores_summary, individual_scores, participants)

    team_section <> "\n\n" <> individual_section
  end

  defp build_team_scores_csv(scores_summary) do
    header = "TEAM SCORES\nQuestion,Combined Team Score"

    rows =
      Enum.map_join(scores_summary, "\n", fn score ->
        team_value =
          if score.combined_team_value, do: "#{round(score.combined_team_value)}/10", else: ""

        "#{csv_escape(score.title)},#{team_value}"
      end)

    header <> "\n" <> rows
  end

  defp build_individual_scores_csv(scores_summary, individual_scores, participants) do
    participant_names = Enum.map(participants, & &1.name)

    header =
      "INDIVIDUAL SCORES\nQuestion," <> Enum.map_join(participant_names, ",", &csv_escape/1)

    rows =
      Enum.map_join(scores_summary, "\n", fn score ->
        question_scores = Map.get(individual_scores, score.question_index, [])

        score_values =
          Enum.map_join(
            participants,
            ",",
            &get_participant_score(&1, question_scores, score.scale_type)
          )

        "#{csv_escape(score.title)},#{score_values}"
      end)

    header <> "\n" <> rows
  end

  defp get_participant_score(participant, question_scores, scale_type) do
    case Enum.find(question_scores, &(&1.participant_id == participant.id)) do
      nil -> ""
      s -> format_score_value(s.value, scale_type)
    end
  end

  defp build_strengths_concerns_csv(scores_summary) do
    grouped = Enum.group_by(scores_summary, & &1.color)
    strengths = Map.get(grouped, :green, [])
    concerns = Map.get(grouped, :red, [])

    strength_lines =
      if Enum.empty?(strengths) do
        "STRENGTHS\nNo strengths identified"
      else
        header = "STRENGTHS\nQuestion,Score"

        rows =
          Enum.map_join(strengths, "\n", fn s ->
            "#{csv_escape(s.title)},#{round(s.combined_team_value)}/10"
          end)

        header <> "\n" <> rows
      end

    concern_lines =
      if Enum.empty?(concerns) do
        "AREAS OF CONCERN\nNo areas of concern identified"
      else
        header = "AREAS OF CONCERN\nQuestion,Score"

        rows =
          Enum.map_join(concerns, "\n", fn s ->
            "#{csv_escape(s.title)},#{round(s.combined_team_value)}/10"
          end)

        header <> "\n" <> rows
      end

    strength_lines <> "\n\n" <> concern_lines
  end

  defp build_notes_csv(notes) do
    if Enum.empty?(notes) do
      "NOTES\nNo notes recorded"
    else
      header = "NOTES\nNote"
      rows = Enum.map_join(notes, "\n", fn note -> csv_escape(note.content) end)
      header <> "\n" <> rows
    end
  end

  defp build_actions_csv(actions, _report_type) do
    if Enum.empty?(actions) do
      "ACTION ITEMS\nNo action items recorded"
    else
      header = "ACTION ITEMS\nAction"
      rows = Enum.map_join(actions, "\n", fn action -> csv_escape(action.description) end)
      header <> "\n" <> rows
    end
  end

  # Helpers

  defp csv_escape(nil), do: ""

  defp csv_escape(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end

  defp csv_escape(value), do: to_string(value)

  defp format_score_value(value, "balance") when value > 0, do: "+#{value}"
  defp format_score_value(value, _scale_type), do: to_string(value)

  defp format_datetime(nil), do: ""

  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  end
end
