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
    plug :store_external_return_to
    plug :maybe_dev_auto_login
    plug :assign_dev_mode
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :internal_api do
    plug :accepts, ["json"]
    plug PortalWeb.Plugs.ApiAuth
  end

  # Health check routes (no auth required)
  scope "/health", PortalWeb do
    pipe_through :api

    get "/", HealthController, :index
    get "/ready", HealthController, :ready
  end

  # Internal API (cross-app token validation)
  scope "/api/internal", PortalWeb.Api do
    pipe_through [:internal_api]

    post "/auth/validate", AuthController, :validate
  end

  # Public routes
  scope "/", PortalWeb do
    pipe_through :browser

    get "/", PageController, :landing
    get "/home", PageController, :home
    get "/about", PageController, :about
    get "/privacy", PageController, :privacy
    get "/contact", PageController, :contact
    get "/apps/:app_id", PageController, :app_detail
    post "/apps/:app_id/notify", PageController, :notify

    live_session :public,
      on_mount: [{PortalWeb.UserAuth, :mount_current_scope}] do
      live "/coming-soon", ComingSoonLive, :index
    end
  end

  # Development routes
  if Application.compile_env(:portal, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PortalWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/dev", PortalWeb do
      pipe_through :browser

      post "/admin-login", DevController, :admin_login
    end
  end

  ## Admin routes (super admin only)

  scope "/admin", PortalWeb do
    pipe_through [:browser, :require_authenticated_user]

    # Non-LiveView admin routes (CSV export)
    get "/signups/export", Admin.SignupsController, :export

    live_session :require_super_admin,
      on_mount: [
        {PortalWeb.UserAuth, :require_authenticated},
        {PortalWeb.UserAuth, :require_super_admin}
      ] do
      live "/", Admin.DashboardLive, :index
      live "/users", Admin.UsersLive, :index
      live "/users/new", Admin.UsersLive, :new
      live "/users/:id/edit", Admin.UsersLive, :edit
      live "/signups", Admin.SignupsLive, :index
      live "/tools", Admin.ToolsLive, :index
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
    delete "/users/delete-account", UserSessionController, :delete_account
  end

  scope "/", PortalWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{PortalWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
      live "/users/forgot-password", UserLive.ForgotPassword, :new
      live "/users/reset-password/:token", UserLive.ResetPassword, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  # Dev-only plugs (no-op in prod/test)
  if Application.compile_env(:portal, :dev_routes) do
    alias PortalWeb.Plugs.DevAutoLogin

    defp maybe_dev_auto_login(conn, _opts) do
      DevAutoLogin.call(conn, [])
    end

    defp assign_dev_mode(conn, _opts), do: assign(conn, :dev_mode, true)
  else
    defp maybe_dev_auto_login(conn, _opts), do: conn
    defp assign_dev_mode(conn, _opts), do: assign(conn, :dev_mode, false)
  end
end
