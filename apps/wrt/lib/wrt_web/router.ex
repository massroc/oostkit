defmodule WrtWeb.Router do
  use WrtWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_root_layout, html: {WrtWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :portal_auth do
    plug WrtWeb.Plugs.PortalAuth
  end

  pipeline :require_portal_or_wrt_super_admin do
    plug WrtWeb.Plugs.PortalAuth
    plug WrtWeb.Plugs.RequirePortalOrWrtSuperAdmin
  end

  # Health check routes (no auth required)
  scope "/health", WrtWeb do
    pipe_through :api

    get "/", HealthController, :index
    get "/ready", HealthController, :ready
  end

  # Public routes
  scope "/", WrtWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create
  end

  # Super admin auth routes (no auth required)
  scope "/admin", WrtWeb.SuperAdmin, as: :super_admin do
    pipe_through :browser

    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  # Super admin protected routes (Portal or WRT auth required)
  scope "/admin", WrtWeb.SuperAdmin, as: :super_admin do
    pipe_through [:browser, :require_portal_or_wrt_super_admin]

    get "/dashboard", DashboardController, :index
    get "/orgs", OrgController, :index
    get "/orgs/:id", OrgController, :show
    post "/orgs/:id/approve", OrgController, :approve
    post "/orgs/:id/reject", OrgController, :reject
    post "/orgs/:id/suspend", OrgController, :suspend
  end

  # Org-scoped routes
  scope "/org/:org_slug", WrtWeb.Org, as: :org do
    pipe_through :browser

    # Auth routes
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete

    # Protected org routes (will add auth plug later)
    get "/dashboard", DashboardController, :index

    # Campaign routes
    resources "/campaigns", CampaignController, only: [:new, :create, :show] do
      get "/seed", SeedController, :index
      post "/seed/upload", SeedController, :upload
      post "/seed/add", SeedController, :add

      # Round routes
      resources "/rounds", RoundController, only: [:index, :create, :show] do
        post "/close", RoundController, :close
        post "/extend", RoundController, :extend
      end

      get "/results", ResultsController, :index
      get "/export/csv", ExportController, :csv
      get "/export/pdf", ExportController, :pdf
    end
  end

  # Nominator routes (public, token-authenticated)
  scope "/org/:org_slug/nominate", WrtWeb.Nominator, as: :nominate do
    pipe_through :browser

    get "/invalid", AuthController, :invalid
    get "/:token", AuthController, :landing
    post "/request-link", AuthController, :request_link
    post "/verify/code", AuthController, :verify
    get "/form", NominationController, :edit
    post "/submit", NominationController, :submit
  end

  # Webhook routes
  scope "/webhooks", WrtWeb do
    pipe_through :api

    post "/email/:provider", WebhookController, :email
  end

  # Development routes
  if Application.compile_env(:wrt, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WrtWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
