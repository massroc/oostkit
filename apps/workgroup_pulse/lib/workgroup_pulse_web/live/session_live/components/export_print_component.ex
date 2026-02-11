defmodule WorkgroupPulseWeb.SessionLive.Components.ExportPrintComponent do
  @moduledoc """
  Renders a hidden div with print-optimized static HTML for PDF capture via html2pdf.js.
  Content switches based on export_report_type (:full or :team).
  """
  use Phoenix.Component

  attr :export_report_type, :string, required: true
  attr :session, :map, required: true
  attr :participants, :list, required: true
  attr :scores_summary, :list, required: true
  attr :individual_scores, :map, required: true
  attr :strengths, :list, required: true
  attr :concerns, :list, required: true
  attr :all_notes, :list, required: true
  attr :all_actions, :list, required: true
  attr :summary_template, :map, required: true

  def render(assigns) do
    all_questions =
      case assigns.summary_template do
        %{questions: q} when is_list(q) -> q
        _ -> []
      end

    assigns = assign(assigns, :all_questions, all_questions)

    ~H"""
    <div id="export-print-wrapper" style="overflow:hidden;height:0;width:0;">
      <div
        id="export-print-content"
        style="box-sizing:border-box;width:960px;overflow:hidden;background:#fff;padding:28px 32px;font-family:system-ui,-apple-system,sans-serif;color:#1e293b;font-size:12px;line-height:1.4;"
      >
        <%!-- Header --%>
        <div style="text-align:center;margin-bottom:16px;padding-bottom:12px;border-bottom:2px solid #e2e8f0;">
          <h1 style="font-size:20px;font-weight:bold;margin:0 0 4px 0;">
            <%= if @export_report_type == "full" do %>
              Full Workshop Report
            <% else %>
              Team Report
            <% end %>
          </h1>
          <p style="color:#64748b;font-size:14px;margin:0;">
            Session {@session.code}
          </p>
          <p style="color:#94a3b8;font-size:12px;margin:4px 0 0 0;">
            <%= if @session.started_at do %>
              Started: {format_datetime(@session.started_at)}
            <% end %>
            <%= if @session.completed_at do %>
              — Completed: {format_datetime(@session.completed_at)}
            <% end %>
          </p>
        </div>

        <%= if @export_report_type == "full" do %>
          {render_full_report(assigns)}
        <% else %>
          {render_team_report(assigns)}
        <% end %>
      </div>
    </div>
    """
  end

  defp render_full_report(assigns) do
    active_participants =
      Enum.filter(assigns.participants, fn p -> not p.is_observer end)

    assigns = assign(assigns, :active_participants, active_participants)

    ~H"""
    <%!-- Participants --%>
    <div style="margin-bottom:20px;page-break-inside:avoid;">
      <h2 style="font-size:14px;font-weight:bold;margin:0 0 6px 0;">Participants</h2>
      <table style="width:100%;border-collapse:collapse;table-layout:fixed;">
        <thead>
          <tr>
            <th style="text-align:left;padding:4px 10px;border-bottom:2px solid #e2e8f0;font-size:11px;color:#64748b;">
              Name
            </th>
            <th style="text-align:left;padding:4px 10px;border-bottom:2px solid #e2e8f0;font-size:11px;color:#64748b;">
              Role
            </th>
          </tr>
        </thead>
        <tbody>
          <%= for p <- @participants do %>
            <tr>
              <td style="padding:3px 10px;border-bottom:1px solid #f1f5f9;">{p.name}</td>
              <td style="padding:3px 10px;border-bottom:1px solid #f1f5f9;">{participant_role(p)}</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>

    <%!-- Individual Scores Grid --%>
    <div style="margin-bottom:20px;page-break-inside:avoid;">
      <h2 style="font-size:14px;font-weight:bold;margin:0 0 6px 0;">Individual Scores</h2>
      <table style="width:100%;border-collapse:collapse;table-layout:fixed;">
        <thead>
          <tr>
            <th style="text-align:left;padding:4px 8px;border-bottom:2px solid #e2e8f0;font-size:11px;color:#64748b;">
              Question
            </th>
            <%= for p <- @active_participants do %>
              <th style="text-align:center;padding:4px 6px;border-bottom:2px solid #e2e8f0;font-size:10px;color:#64748b;max-width:80px;overflow:hidden;text-overflow:ellipsis;">
                {p.name}
              </th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <%= for q <- @all_questions do %>
            <% question_scores = Map.get(@individual_scores, q.index, []) %>
            <% scores_by_pid = Map.new(question_scores, &{&1.participant_id, &1}) %>
            <tr>
              <td style="padding:3px 8px;border-bottom:1px solid #f1f5f9;font-weight:500;">
                {q.title}
              </td>
              <%= for p <- @active_participants do %>
                <% score_data = Map.get(scores_by_pid, p.id) %>
                <td style={"text-align:center;padding:3px 6px;border-bottom:1px solid #f1f5f9;font-weight:bold;" <> cell_bg_style(score_data && score_data.color)}>
                  <%= if score_data do %>
                    {format_score_value(q.scale_type, score_data.value)}
                  <% else %>
                    —
                  <% end %>
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>

    <%!-- Team Scores --%>
    {render_team_scores(assigns)}

    <%!-- Strengths & Concerns --%>
    {render_strengths_concerns(assigns)}

    <%!-- Notes with authors --%>
    {render_notes(assigns, :full)}

    <%!-- Actions with owners --%>
    {render_actions(assigns, :full)}
    """
  end

  defp render_team_report(assigns) do
    ~H"""
    <%!-- Team Scores --%>
    {render_team_scores(assigns)}

    <%!-- Strengths & Concerns --%>
    {render_strengths_concerns(assigns)}

    <%!-- Notes without authors --%>
    {render_notes(assigns, :team)}

    <%!-- Actions without owners --%>
    {render_actions(assigns, :team)}
    """
  end

  defp render_team_scores(assigns) do
    ~H"""
    <div style="margin-bottom:20px;page-break-inside:avoid;">
      <h2 style="font-size:14px;font-weight:bold;margin:0 0 6px 0;">Team Scores</h2>
      <div style="display:flex;flex-wrap:wrap;gap:10px;">
        <%= for score <- @scores_summary do %>
          <div style={"width:calc(25% - 8px);border:2px solid " <> card_border_color(score.color) <> ";border-radius:6px;padding:10px;text-align:center;background:" <> card_bg_color(score.color) <> ";"}>
            <div style="font-size:9px;color:#94a3b8;margin-bottom:2px;">
              Q{score.question_index + 1}
            </div>
            <div style={"font-size:20px;font-weight:bold;color:" <> text_color(score.color) <> ";"}>
              <%= if score.combined_team_value do %>
                {round(score.combined_team_value)}/10
              <% else %>
                —
              <% end %>
            </div>
            <div style="font-size:10px;color:#64748b;margin-top:2px;">
              {score.title}
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_strengths_concerns(assigns) do
    ~H"""
    <%= if length(@strengths) > 0 or length(@concerns) > 0 do %>
      <div style="display:flex;gap:12px;margin-bottom:20px;page-break-inside:avoid;">
        <%= if length(@strengths) > 0 do %>
          <div style="flex:1;border:1px solid #86efac;border-radius:6px;padding:10px;background:#f0fdf4;">
            <h3 style="font-size:13px;font-weight:600;color:#16a34a;margin:0 0 6px 0;">
              Strengths ({length(@strengths)})
            </h3>
            <%= for item <- @strengths do %>
              <div style="display:flex;justify-content:space-between;padding:2px 0;font-size:12px;">
                <span>{item.title}</span>
                <span style="color:#16a34a;font-weight:600;">
                  {round(item.combined_team_value)}/10
                </span>
              </div>
            <% end %>
          </div>
        <% end %>
        <%= if length(@concerns) > 0 do %>
          <div style="flex:1;border:1px solid #fca5a5;border-radius:6px;padding:10px;background:#fef2f2;">
            <h3 style="font-size:13px;font-weight:600;color:#dc2626;margin:0 0 6px 0;">
              Areas of Concern ({length(@concerns)})
            </h3>
            <%= for item <- @concerns do %>
              <div style="display:flex;justify-content:space-between;padding:2px 0;font-size:12px;">
                <span>{item.title}</span>
                <span style="color:#dc2626;font-weight:600;">
                  {round(item.combined_team_value)}/10
                </span>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  defp render_notes(assigns, report_type) do
    assigns = assign(assigns, :report_type, report_type)

    ~H"""
    <div style="margin-bottom:20px;">
      <h2 style="font-size:14px;font-weight:bold;margin:0 0 6px 0;">Notes</h2>
      <%= if Enum.empty?(@all_notes) do %>
        <p style="color:#94a3b8;font-style:italic;">No notes recorded.</p>
      <% else %>
        <table style="width:100%;border-collapse:collapse;table-layout:fixed;">
          <thead>
            <tr>
              <th style="text-align:left;padding:4px 10px;border-bottom:2px solid #e2e8f0;font-size:11px;color:#64748b;">
                Note
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for note <- @all_notes do %>
              <tr style="page-break-inside:avoid;">
                <td style="padding:3px 10px;border-bottom:1px solid #f1f5f9;vertical-align:top;">
                  {note.content}
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp render_actions(assigns, report_type) do
    assigns = assign(assigns, :report_type, report_type)

    ~H"""
    <div style="margin-bottom:20px;">
      <h2 style="font-size:14px;font-weight:bold;margin:0 0 6px 0;">Action Items</h2>
      <%= if Enum.empty?(@all_actions) do %>
        <p style="color:#94a3b8;font-style:italic;">No action items recorded.</p>
      <% else %>
        <table style="width:100%;border-collapse:collapse;table-layout:fixed;">
          <thead>
            <tr>
              <th style="text-align:left;padding:4px 10px;border-bottom:2px solid #e2e8f0;font-size:11px;color:#64748b;">
                Action
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for action <- @all_actions do %>
              <tr style="page-break-inside:avoid;">
                <td style="padding:3px 10px;border-bottom:1px solid #f1f5f9;vertical-align:top;">
                  {action.description}
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  # Helpers

  defp participant_role(%{is_facilitator: true}), do: "Facilitator"
  defp participant_role(%{is_observer: true}), do: "Observer"
  defp participant_role(_), do: "Participant"

  defp format_datetime(nil), do: ""

  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  end

  defdelegate format_score_value(scale_type, value),
    to: WorkgroupPulseWeb.SessionLive.GridHelpers

  defp cell_bg_style(:green), do: "background:#dcfce7;"
  defp cell_bg_style(:amber), do: "background:#fef9c3;"
  defp cell_bg_style(:red), do: "background:#fee2e2;"
  defp cell_bg_style(_), do: ""

  defp text_color(:green), do: "#16a34a"
  defp text_color(:amber), do: "#d97706"
  defp text_color(:red), do: "#dc2626"
  defp text_color(_), do: "#64748b"

  defp card_bg_color(:green), do: "#f0fdf4"
  defp card_bg_color(:amber), do: "#fffbeb"
  defp card_bg_color(:red), do: "#fef2f2"
  defp card_bg_color(_), do: "#f8fafc"

  defp card_border_color(:green), do: "#86efac"
  defp card_border_color(:amber), do: "#fde68a"
  defp card_border_color(:red), do: "#fca5a5"
  defp card_border_color(_), do: "#e2e8f0"
end
