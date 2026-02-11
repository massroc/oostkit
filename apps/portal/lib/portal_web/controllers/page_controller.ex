defmodule PortalWeb.PageController do
  use PortalWeb, :controller

  alias Portal.Tools
  alias Portal.Tools.Tool

  def landing(conn, _params) do
    if conn.assigns[:current_scope] && conn.assigns.current_scope.user do
      redirect(conn, to: ~p"/home")
    else
      tools = Tools.list_tools()
      live_tools = Enum.filter(tools, &(Tool.effective_status(&1) == :live))

      render(conn, :landing,
        page_title: "Tools for building democratic workplaces",
        meta_description:
          "Practical online tools built on Open Systems Theory — design organisations where people manage their own work.",
        tools: tools,
        live_tools: live_tools
      )
    end
  end

  def home(conn, _params) do
    tools = Tools.list_tools()
    user = get_in(conn.assigns, [:current_scope, Access.key(:user)])

    show_onboarding =
      user != nil and user.onboarding_completed == false

    render(conn, :home,
      page_title: "Home",
      tools: tools,
      show_onboarding: show_onboarding,
      onboarding_tools: tools
    )
  end

  def app_detail(conn, %{"app_id" => app_id} = params) do
    case Tools.get_tool(app_id) do
      nil ->
        conn
        |> put_flash(:error, "Application not found")
        |> redirect(to: ~p"/home")

      tool ->
        render(conn, :app_detail,
          page_title: tool.name,
          meta_description: tool.description || tool.tagline,
          tool: tool,
          subscribed: params["subscribed"] == "true"
        )
    end
  end

  def notify(conn, %{"app_id" => app_id, "signup" => signup_params}) do
    case Tools.get_tool(app_id) do
      nil ->
        conn
        |> put_flash(:error, "Application not found")
        |> redirect(to: ~p"/home")

      tool ->
        params = Map.put(signup_params, "context", "tool:#{tool.id}")

        case Portal.Marketing.create_interest_signup(params) do
          {:ok, _signup} ->
            redirect(conn, to: ~p"/apps/#{tool.id}?subscribed=true")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Please provide a valid email address.")
            |> redirect(to: ~p"/apps/#{tool.id}")
        end
    end
  end
end
