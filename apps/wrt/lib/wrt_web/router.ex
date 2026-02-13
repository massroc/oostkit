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

  pipeline :require_portal_user do
    plug OostkitShared.Plugs.PortalAuth
    plug OostkitShared.Plugs.RequirePortalUser, endpoint: WrtWeb.Endpoint
  end

  # Health check routes (no auth required)
  scope "/health", WrtWeb do
    pipe_through :api

    get "/", HealthController, :index
    get "/ready", HealthController, :ready
  end

  # Landing page — users arrive via Portal, already authenticated
  scope "/", WrtWeb do
    pipe_through [:browser, :require_portal_user]

    get "/", PageController, :home
    post "/dismiss-landing", PageController, :dismiss_landing
  end

  # Org-scoped routes (Portal auth required)
  scope "/org/:org_slug", WrtWeb.Org, as: :org do
    pipe_through [:browser, :require_portal_user]

    get "/manage", ManageController, :index

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
