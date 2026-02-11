defmodule WorkgroupPulseWeb.Router do
  use WorkgroupPulseWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WorkgroupPulseWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WorkgroupPulseWeb do
    pipe_through :browser

    # Create new session (home page)
    live "/", SessionLive.New, :new

    # Session routes
    live "/session/:code", SessionLive.Show, :show
    live "/session/:code/join", SessionLive.Join, :join

    # Controller routes (for actions that need to set session)
    post "/session/create", SessionController, :create
    post "/session/:code/join", SessionController, :join
  end

  # Development routes
  if Application.compile_env(:workgroup_pulse, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WorkgroupPulseWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
