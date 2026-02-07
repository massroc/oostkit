defmodule PortalWeb.Router do
  use PortalWeb, :router

  import PortalWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PortalWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes
  scope "/", PortalWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/apps/:app_id", PageController, :app_detail
  end

  # Development routes
  if Application.compile_env(:portal, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PortalWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Admin routes (super admin only)

  scope "/admin", PortalWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_super_admin,
      on_mount: [
        {PortalWeb.UserAuth, :require_authenticated},
        {PortalWeb.UserAuth, :require_super_admin}
      ] do
      live "/users", Admin.UsersLive, :index
      live "/users/new", Admin.UsersLive, :new
      live "/users/:id/edit", Admin.UsersLive, :edit
    end
  end

  ## Authentication routes

  scope "/", PortalWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PortalWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", PortalWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{PortalWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
