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
        tools: tools,
        live_tools: live_tools
      )
    end
  end

  def home(conn, _params) do
    tools = Tools.list_tools()

    render(conn, :home,
      page_title: "Home",
      tools: tools
    )
  end

  def app_detail(conn, %{"app_id" => app_id}) do
    case Tools.get_tool(app_id) do
      nil ->
        conn
        |> put_flash(:error, "Application not found")
        |> redirect(to: ~p"/home")

      tool ->
        render(conn, :app_detail,
          page_title: tool.name,
          tool: tool
        )
    end
  end
end
