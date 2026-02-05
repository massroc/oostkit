defmodule PortalWeb.PageController do
  use PortalWeb, :controller

  @apps_config [
    %{
      id: "workgroup_pulse",
      name: "Workgroup Pulse",
      tagline: "6 Criteria for Productive Work",
      description: """
      A self-guided workshop helping teams assess their workgroup health using
      the 6 Criteria framework. Team members rate various aspects of their work
      environment and discuss results together.
      """,
      audience: :team,
      url: "https://pulse.oostkit.com",
      dev_url: "http://localhost:4000",
      requires_auth: false,
      status: :live
    },
    %{
      id: "wrt",
      name: "Workshop Referral Tool",
      tagline: "Participative selection for PDW participants",
      description: """
      Manage the referral process for Participative Design Workshops. Facilitators
      can set up nomination rounds, send invitations, and collect peer nominations
      to build the ideal workshop participant list.
      """,
      audience: :facilitator,
      url: "https://wrt.oostkit.com",
      dev_url: "http://localhost:4001",
      requires_auth: true,
      status: :live
    }
  ]

  def home(conn, _params) do
    facilitator_apps = Enum.filter(@apps_config, &(&1.audience == :facilitator))
    team_apps = Enum.filter(@apps_config, &(&1.audience == :team))

    render(conn, :home,
      page_title: "Home",
      facilitator_apps: facilitator_apps,
      team_apps: team_apps
    )
  end

  def app_detail(conn, %{"app_id" => app_id}) do
    case Enum.find(@apps_config, &(&1.id == app_id)) do
      nil ->
        conn
        |> put_flash(:error, "Application not found")
        |> redirect(to: ~p"/")

      app ->
        render(conn, :app_detail,
          page_title: app.name,
          app: app
        )
    end
  end
end
