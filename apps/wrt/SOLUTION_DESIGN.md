# Workshop Referral Tool (WRT) - Solution Design

Technical architecture and implementation design for the OST Referral Tool.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Web Layer                                │
│  ┌──────────────┐  ┌─────────────┐  ┌───────────────────────┐   │
│  │ Landing Page │  │  Org Admin  │  │  Nominator (Public)   │   │
│  │   Routes     │  │   Routes    │  │       Routes          │   │
│  └──────┬───────┘  └──────┬──────┘  └───────────┬───────────┘   │
│         │                 │                      │               │
│         ▼                 ▼                      ▼               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Phoenix Controllers                      ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Business Logic                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌───────────┐  │
│  │   Orgs     │  │ Campaigns  │  │  Rounds    │  │Nominations│  │
│  │  Context   │  │  Context   │  │  Context   │  │  Context  │  │
│  └────────────┘  └────────────┘  └────────────┘  └───────────┘  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                 │
│  │  People    │  │   Auth     │  │   Mailer   │                 │
│  │  Context   │  │  Context   │  │  Context   │                 │
│  └────────────┘  └────────────┘  └────────────┘                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Data Layer                                  │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Tenant Manager                           ││
│  │         (Schema switching, migrations, lifecycle)           ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│         ┌────────────────────┼────────────────────┐             │
│         ▼                    ▼                    ▼             │
│  ┌─────────────┐     ┌─────────────┐      ┌─────────────┐      │
│  │   public    │     │  tenant_a   │      │  tenant_b   │      │
│  │   schema    │     │   schema    │      │   schema    │      │
│  │             │     │             │      │             │      │
│  │ - orgs      │     │ - org_admins│      │ - org_admins│      │
│  │             │     │ - campaigns │      │ - campaigns │      │
│  │             │     │ - rounds    │      │ - rounds    │      │
│  │             │     │ - people    │      │ - people    │      │
│  │             │     │ - etc.      │      │ - etc.      │      │
│  └─────────────┘     └─────────────┘      └─────────────┘      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   External Services                              │
│  ┌─────────────────────────┐  ┌──────────────────────────────┐  │
│  │   Email Service         │  │   Background Jobs (Oban)     │  │
│  │   (Postmark/Sendgrid)   │  │   - Email sending            │  │
│  │                         │  │   - Round auto-close         │  │
│  │   - Delivery webhooks   │  │   - Reminder scheduling      │  │
│  │   - Open/click tracking │  │   - Data retention cleanup   │  │
│  └─────────────────────────┘  └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Module Structure

```
lib/
├── wrt/
│   ├── application.ex              # OTP Application (Finch pool for Portal API, ETS cache table)
│   │
│   ├── repo.ex                     # Ecto Repo
│   │
│   ├── tenant_manager.ex           # Multi-tenancy orchestration ✓
│   │
│   ├── auth/                       # Legacy authentication helpers (retained for data compat)
│   │   └── password.ex             # Shared hash_password/1 and valid_password?/2
│   │
│   ├── platform/                   # Public schema (cross-tenant) ✓
│   │   ├── organisation.ex         # Schema
│   │   ├── super_admin.ex          # Schema (legacy, retained for data compat)
│   │   └── platform.ex             # Context (includes get_organisation_by_admin_email/1)
│   │
│   ├── orgs/                       # Org management (tenant-scoped) ✓
│   │   ├── org_admin.ex            # Schema (delegates to Auth.Password)
│   │   └── orgs.ex                 # Context
│   │
│   ├── campaigns/                  # Campaign management ✓
│   │   ├── campaign.ex             # Schema
│   │   ├── campaign_admin.ex       # Schema (delegates to Auth.Password)
│   │   └── campaigns.ex            # Context
│   │
│   ├── rounds/                     # Round management ✓
│   │   ├── round.ex                # Schema
│   │   ├── contact.ex              # Schema (invitation tracking)
│   │   └── rounds.ex               # Context
│   │
│   ├── people/                     # People & nominations ✓
│   │   ├── person.ex               # Schema
│   │   ├── nomination.ex           # Schema
│   │   └── people.ex               # Context
│   │
│   ├── magic_links/                # Magic link authentication ✓
│   │   ├── magic_link.ex           # Schema (24hr token, 15min code)
│   │   └── magic_links.ex          # Context (create, verify, use)
│   │
│   ├── emails.ex                   # Email composition ✓
│   │                               # - Invitation, verification, reminder emails
│   │                               # - Data retention warning emails (to org admins)
│   │                               # - HTML and text templates
│   │
│   ├── reports.ex                  # Reporting context ✓
│   │                               # - Campaign statistics
│   │                               # - Convergence metrics (scoped by campaign_id)
│   │                               # - Top nominees
│   │
│   ├── logger.ex                   # Structured logging ✓
│   │                               # - Rate limit events only
│   │
│   ├── telemetry.ex                # Business telemetry ✓
│   │                               # - Magic links
│   │                               # - Nominations
│   │                               # - Rate limiting
│   │
│   ├── mailer.ex                   # Swoosh mailer ✓
│   │
│   └── workers/                    # Oban workers ✓
│       ├── send_invitation_email.ex
│       ├── send_round_invitations.ex
│       ├── send_reminder_email.ex
│       ├── send_verification_code.ex
│       ├── cleanup_expired_magic_links.ex
│       └── data_retention_check.ex
│
├── wrt_web/
│   ├── router.ex                   # ✓
│   │
│   ├── endpoint.ex                 # ✓ (with rate limiter)
│   │
│   ├── portal_auth_client.ex        # Finch HTTP client for Portal token validation ✓
│   │                                # - Calls POST /api/internal/auth/validate
│   │                                # - ETS cache with 5-minute TTL
│   │                                # - Configured via portal_api_url, portal_api_key
│   │
│   ├── plugs/
│   │   ├── portal_auth.ex           # Portal cross-app auth plug ✓
│   │   │                            # - Reads _oostkit_token cookie
│   │   │                            # - Validates via PortalAuthClient
│   │   │                            # - Sets :portal_user assign on conn
│   │   │                            # - Dev bypass: assigns fake dev admin when no cookie
│   │   │                            #   or when validation fails (e.g., Portal unreachable)
│   │   │
│   │   ├── require_portal_user.ex   # Portal user auth plug ✓
│   │   │                            # - Requires any valid Portal user (enabled)
│   │   │                            # - Redirects to Portal login if not authenticated
│   │   │                            # - Appends return_to query param with current WRT URL
│   │   │
│   │   ├── tenant_plug.ex           # Tenant resolution from URL ✓
│   │   │                            # - Extracts org slug from /org/:slug routes
│   │   │                            # - Sets :current_org and :tenant assigns
│   │   │
│   │   └── rate_limiter.ex         # PlugAttack rate limiting ✓
│   │                               # - Magic links: 3/min
│   │                               # - Nominations: 10/min
│   │                               # - Webhooks: 100/min
│   │                               # - General: 120/min
│   │
│   ├── controllers/
│   │   ├── page_controller.ex      # Entry flow (landing, no_org, inactive) ✓
│   │   │                           # - Resolves org by portal_user email
│   │   │                           # - Shows landing page or redirects to /org/:slug/manage
│   │   │                           # - Handles "don't show again" cookie
│   │   │
│   │   ├── org/                    # ✓
│   │   │   ├── manage_controller.ex  # Process Manager dashboard (was dashboard_controller)
│   │   │   ├── campaign_controller.ex
│   │   │   ├── round_controller.ex
│   │   │   ├── seed_controller.ex
│   │   │   ├── results_controller.ex
│   │   │   └── export_controller.ex  # CSV/PDF with filters
│   │   │
│   │   ├── nominator/              # ✓
│   │   │   ├── auth_controller.ex    # Magic link flow
│   │   │   ├── auth_html.ex          # Landing, verify templates
│   │   │   ├── nomination_controller.ex
│   │   │   └── nomination_html.ex    # Nomination form
│   │   │
│   │   ├── health_controller.ex    # Health check endpoints ✓
│   │   │                           # - /health (liveness)
│   │   │                           # - /health/ready (readiness)
│   │   │
│   │   └── webhook_controller.ex       # ✓ Postmark/SendGrid webhooks
│   │
│   ├── telemetry.ex                # Metrics definitions ✓
│   │
│   ├── components/                 # ✓
│   │   ├── layouts.ex
│   │   └── core_components.ex      # Includes campaign/round/source status badge helpers
│   │
│   └── templates/                  # ✓
│       └── nominator/
│           └── auth_html/
│               ├── landing.html.heex
│               ├── verify_form.html.heex
│               ├── invalid_link.html.heex
│               └── round_closed.html.heex

test/
├── support/
│   ├── data_case.ex                # Test case with tenant support ✓
│   ├── conn_case.ex                # Controller test case ✓
│   └── factory.ex                  # ExMachina factories ✓
│
├── wrt/
│   ├── emails_test.exs             # Email composition tests ✓
│   ├── magic_links_test.exs        # MagicLinks context tests ✓
│   ├── platform_test.exs           # Platform context tests ✓
│   ├── reports_test.exs            # Reports context tests ✓
│   └── workers/
│       ├── cleanup_expired_magic_links_test.exs ✓
│       ├── data_retention_check_test.exs ✓
│       ├── send_invitation_email_test.exs ✓
│       ├── send_reminder_email_test.exs ✓
│       └── send_round_invitations_test.exs ✓
│
└── wrt_web/
    ├── plugs/
    │   └── portal_auth_test.exs    # PortalAuth plug tests ✓
    └── controllers/
        ├── health_controller_test.exs  # ✓
        ├── page_controller_test.exs    # Entry flow tests ✓
        ├── org/
        │   └── manage_controller_test.exs # Process Manager tests ✓
        └── webhook_controller_test.exs # ✓
```

## Multi-Tenancy Implementation

### Approach: Schema-per-Tenant with Triplex

Use the [Triplex](https://hexdocs.pm/triplex) library for PostgreSQL schema-based multi-tenancy.

### Tenant Lifecycle

```elixir
# Creating a new tenant (on org approval)
defmodule Wrt.TenantManager do
  @tenant_migrations_path "priv/repo/tenant_migrations"

  def create_tenant(org) do
    schema_name = "tenant_#{org.id}"

    with :ok <- Triplex.create(schema_name, Wrt.Repo),
         :ok <- Triplex.migrate(schema_name, Wrt.Repo, @tenant_migrations_path) do
      {:ok, schema_name}
    end
  end

  def drop_tenant(schema_name) do
    Triplex.drop(schema_name, Wrt.Repo)
  end
end
```

### Request Flow with Tenant Context

```elixir
# Plug to extract tenant from URL path
defmodule WrtWeb.Plugs.TenantPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(%{path_info: ["org", org_slug | _rest]} = conn, _opts) do
    case Wrt.Platform.get_org_by_slug(org_slug) do
      {:ok, org} ->
        conn
        |> assign(:current_org, org)
        |> assign(:tenant, "tenant_#{org.id}")

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> halt()
    end
  end

  def call(conn, _opts), do: conn
end
```

### Repo with Tenant Prefix

```elixir
# All tenant-scoped queries use prefix option
defmodule Wrt.Campaigns do
  alias Wrt.Repo
  alias Wrt.Campaigns.Campaign

  def list_campaigns(tenant) do
    Campaign
    |> Repo.all(prefix: tenant)
  end

  def get_campaign(tenant, id) do
    Campaign
    |> Repo.get(id, prefix: tenant)
  end
end
```

### Migration Strategy

Two sets of migrations:
- `priv/repo/migrations/` - Public schema (organisations)
- `priv/repo/tenant_migrations/` - Tenant schemas (campaigns, rounds, etc.)

```elixir
# Mix task to migrate all tenants
defmodule Mix.Tasks.Wrt.MigrateTenants do
  use Mix.Task

  def run(_args) do
    Application.ensure_all_started(:wrt)

    Wrt.Platform.list_approved_orgs()
    |> Enum.each(fn org ->
      schema = "tenant_#{org.id}"
      Triplex.migrate(schema, Wrt.Repo)
    end)
  end
end
```

## URL Structure

```
# Landing page (users arrive via Portal, already authenticated)
GET  /                                    # Entry flow: landing / no_org / inactive
POST /dismiss-landing                     # "Don't show again" + redirect to manage

# Org-scoped routes (Portal user auth required)
GET  /org/:slug/manage                    # Process Manager dashboard
GET  /org/:slug/campaigns/new             # Create campaign
POST /org/:slug/campaigns
GET  /org/:slug/campaigns/:id             # Campaign detail
GET  /org/:slug/campaigns/:id/seed        # Manage seed group
POST /org/:slug/campaigns/:id/seed/upload # CSV upload
POST /org/:slug/campaigns/:id/seed/add    # Manual add
GET  /org/:slug/campaigns/:id/rounds      # Round management
POST /org/:slug/campaigns/:id/rounds      # Start new round
GET  /org/:slug/campaigns/:id/rounds/:num # Round detail
POST /org/:slug/campaigns/:id/rounds/:num/close
POST /org/:slug/campaigns/:id/rounds/:num/extend
GET  /org/:slug/campaigns/:id/results     # Convergence view
GET  /org/:slug/campaigns/:id/export/csv  # Download CSV
GET  /org/:slug/campaigns/:id/export/pdf  # Download PDF

# Nominator routes (public, token-authenticated via magic link)
GET  /org/:slug/nominate/invalid          # Invalid link page
GET  /org/:slug/nominate/:token           # Landing with magic link
POST /org/:slug/nominate/request-link     # Request magic link email
POST /org/:slug/nominate/verify/code      # Verify magic link code
GET  /org/:slug/nominate/form             # Nomination form (authenticated)
POST /org/:slug/nominate/submit           # Submit nominations

# Webhook routes
POST /webhooks/email/:provider            # Email tracking callbacks

# Health checks (no auth)
GET  /health                              # Liveness check
GET  /health/ready                        # Readiness check
```

## Authentication Flows

### Admin Authentication (Portal-Delegated)

All admin authentication is delegated to Portal. WRT has no login pages, registration
forms, password-based auth, or super admin web layer. Users access WRT through the Portal
dashboard, arriving already authenticated via Portal's `_oostkit_token` cookie.

The authentication pipeline consists of two plugs applied at the router level:

1. **`PortalAuth`** — Reads the `_oostkit_token` cookie and validates it against Portal's
   internal API via `PortalAuthClient`. Sets `:portal_user` assign on conn with the user's
   `id`, `email`, `role`, and `enabled` status. Results are cached in ETS with 5-minute TTL.
   In dev mode, if no cookie is present **or if validation fails** (e.g., Portal is unreachable
   from Docker), assigns a fake dev admin user (`dev@oostkit.local`, `super_admin` role) so
   WRT routes work without requiring Portal to be running. In prod, validation failure sets
   `:portal_user` to `nil` (same as no cookie).

2. **`RequirePortalUser`** — For all authenticated routes (`/` and `/org/:slug/*`). Checks
   that any valid `portal_user` exists and is enabled. Redirects to Portal login if not.
   Appends a `return_to` query param containing the user's current WRT URL so that Portal
   can redirect back after successful login (e.g., `?return_to=http://localhost:4001/org/acme/manage`).
   Portal validates the URL origin against its `:tool_urls` config before accepting it.

```elixir
# Router pipeline
pipeline :require_portal_user do
  plug WrtWeb.Plugs.PortalAuth
  plug WrtWeb.Plugs.RequirePortalUser
end
```

Unauthenticated users are redirected to `portal_login_url` (configured per environment) with the `return_to` param.

### Entry Flow (Landing Page)

When a Portal-authenticated user arrives at `GET /`, the `PageController` resolves their
organisation by matching their Portal email against `Organisation.admin_email`:

- **No matching org** → renders `no_org.html.heex` (explains they need an org set up)
- **Org inactive/suspended** → renders `inactive.html.heex` (explains org is not active)
- **Org active + no skip cookie** → renders `landing.html.heex` (explains the referral
  process, with a "don't show again" checkbox)
- **Org active + skip cookie set** → redirects directly to `/org/:slug/manage`

The "don't show again" action (`POST /dismiss-landing`) sets a `wrt_skip_landing` cookie
(1-year expiry) and redirects to the org's manage page.

### Nominator Magic Link Flow

```
1. Nominator receives invitation email with link:
   /org/acme/nominate/abc123def456

2. Clicking link shows page: "Enter your email to continue"
   - Validates token exists and round is open
   - Does NOT auto-authenticate (prevents email forwarding abuse)

3. Nominator enters email, system sends magic code:
   POST /org/acme/nominate/request-link
   - Generates 6-digit code, valid 15 minutes
   - Sends email with code

4. Nominator enters code:
   GET /org/acme/nominate/verify/123456
   - Validates code matches email + token
   - Creates session cookie scoped to this round

5. Nominator accesses form:
   GET /org/acme/nominate/form
   - Session cookie required
   - Can return anytime while round is open
```

## Email System

### Swoosh Configuration

```elixir
# config/config.exs
config :wrt, Wrt.Mailer,
  adapter: Swoosh.Adapters.Postmark,
  api_key: {:system, "POSTMARK_API_KEY"}

# For tracking, use Postmark's message streams with tracking enabled
```

### Email Templates

```elixir
defmodule Wrt.Mailer.Templates.Invitation do
  import Swoosh.Email

  def build(contact, campaign, magic_token) do
    new()
    |> to({contact.person.name, contact.person.email})
    |> from({"Wrt Tool", "noreply@wrt.example.com"})
    |> subject("#{campaign.name} - We need your input")
    |> html_body(render_html(contact, campaign, magic_token))
    |> text_body(render_text(contact, campaign, magic_token))
    |> put_provider_option(:track_opens, true)
    |> put_provider_option(:track_links, "HtmlAndText")
    |> put_provider_option(:metadata, %{
      contact_id: contact.id,
      round_id: contact.round_id
    })
  end
end
```

### Webhook Handler

```elixir
defmodule WrtWeb.WebhookController do
  use WrtWeb, :controller

  def handle(conn, %{"provider" => "postmark"} = params) do
    case params["RecordType"] do
      "Delivery" ->
        update_contact_status(params["Metadata"]["contact_id"], :delivered)

      "Open" ->
        update_contact_status(params["Metadata"]["contact_id"], :opened)

      "Click" ->
        update_contact_status(params["Metadata"]["contact_id"], :clicked)

      "Bounce" ->
        update_contact_status(params["Metadata"]["contact_id"], :bounced)

      "SpamComplaint" ->
        update_contact_status(params["Metadata"]["contact_id"], :spam)

      _ ->
        :ok
    end

    send_resp(conn, 200, "OK")
  end
end
```

## Background Jobs

Using [Oban](https://hexdocs.pm/oban) for reliable background job processing.

### Job Types

```elixir
# Send invitation emails (queued when round starts)
defmodule Wrt.Workers.SendInvitation do
  use Oban.Worker, queue: :emails, max_attempts: 3

  @impl true
  def perform(%Oban.Job{args: %{"contact_id" => contact_id, "tenant" => tenant}}) do
    contact = Rounds.get_contact(tenant, contact_id) |> Repo.preload([:person, :round])
    campaign = Campaigns.get_campaign(tenant, contact.round.campaign_id)
    magic_link = Auth.create_magic_link(tenant, contact)

    Wrt.Mailer.deliver(
      Wrt.Mailer.Templates.Invitation.build(contact, campaign, magic_link.token)
    )
  end
end

# Auto-close round at deadline
defmodule Wrt.Workers.CloseRound do
  use Oban.Worker, queue: :rounds

  @impl true
  def perform(%Oban.Job{args: %{"round_id" => round_id, "tenant" => tenant}}) do
    round = Rounds.get_round(tenant, round_id)

    if round.status == :active do
      Rounds.close_round(tenant, round)
    end

    :ok
  end
end

# Optional reminder emails
defmodule Wrt.Workers.SendReminder do
  use Oban.Worker, queue: :emails

  @impl true
  def perform(%Oban.Job{args: %{"round_id" => round_id, "tenant" => tenant}}) do
    round = Rounds.get_round(tenant, round_id) |> Repo.preload(:campaign)

    if round.status == :active do
      Rounds.list_pending_contacts(tenant, round)
      |> Enum.each(fn contact ->
        Wrt.Mailer.deliver(
          Wrt.Mailer.Templates.Reminder.build(contact, round.campaign)
        )
      end)
    end

    :ok
  end
end

# Data retention check (runs weekly via Oban cron)
defmodule Wrt.Workers.DataRetentionCheck do
  use Oban.Worker, queue: :maintenance, max_attempts: 3

  # Supports three actions:
  # - "check" (default): scans all orgs for campaigns needing warnings or archival
  # - "warn": looks up org, gets all org admins, sends retention warning emails
  #           via Emails.send_retention_warning/3 for each campaign
  # - "archive": archives campaigns past retention period (logs for now)
  #
  # The check action queues separate "warn" and "archive" jobs as needed.
  # Warning emails include campaign name, days remaining, and deletion date.
end
```

### Job Scheduling

```elixir
# When starting a round
def start_round(tenant, campaign) do
  round = create_round(tenant, campaign)

  # Queue invitation emails
  eligible_people(tenant, campaign)
  |> Enum.each(fn person ->
    contact = create_contact(tenant, round, person)

    %{contact_id: contact.id, tenant: tenant}
    |> Wrt.Workers.SendInvitation.new()
    |> Oban.insert()
  end)

  # Schedule round auto-close
  %{round_id: round.id, tenant: tenant}
  |> Wrt.Workers.CloseRound.new(scheduled_at: round.deadline)
  |> Oban.insert()

  # Schedule reminder if enabled
  if round.reminder_enabled do
    reminder_time = DateTime.add(round.deadline, -round.reminder_days, :day)

    %{round_id: round.id, tenant: tenant}
    |> Wrt.Workers.SendReminder.new(scheduled_at: reminder_time)
    |> Oban.insert()
  end

  {:ok, round}
end
```

## Export Implementation

### CSV Export

```elixir
defmodule Wrt.Export.CsvExporter do
  alias NimbleCSV.RFC4180, as: CSV

  def export(tenant, campaign, opts \\ []) do
    people = People.list_with_nomination_counts(tenant, campaign.id)

    people =
      case opts[:filter] do
        :above_threshold -> Enum.filter(people, &(&1.nomination_count >= 2))
        :nominated_only -> Enum.filter(people, &(&1.source == :nominated))
        _ -> people
      end

    headers = ["Name", "Email", "Nomination Count"]

    rows =
      people
      |> Enum.sort_by(& &1.nomination_count, :desc)
      |> Enum.map(fn p -> [p.name, p.email, p.nomination_count] end)

    CSV.dump_to_iodata([headers | rows])
  end
end
```

### PDF Report

Using a library like [ChromicPDF](https://hexdocs.pm/chromic_pdf) or [PDF Generator](https://hexdocs.pm/pdf_generator).

```elixir
defmodule Wrt.Export.PdfReport do
  def generate(tenant, campaign) do
    stats = calculate_stats(tenant, campaign)
    people = People.list_with_nomination_counts(tenant, campaign.id)

    html = render_report_html(campaign, stats, people)

    ChromicPDF.print_to_pdf({:html, html})
  end

  defp calculate_stats(tenant, campaign) do
    %{
      total_contacted: Rounds.count_contacts(tenant, campaign.id),
      total_responded: Rounds.count_responses(tenant, campaign.id),
      total_nominations: People.count_nominations(tenant, campaign.id),
      rounds_completed: Rounds.count_closed(tenant, campaign.id),
      response_rate: calculate_response_rate(tenant, campaign.id)
    }
  end
end
```

## Security Considerations

### Magic Link Security

```elixir
defmodule Wrt.Auth.MagicLink do
  @token_bytes 32
  @code_length 6
  @code_expiry_minutes 15

  def generate_token do
    :crypto.strong_rand_bytes(@token_bytes)
    |> Base.url_encode64(padding: false)
  end

  def generate_code do
    :rand.uniform(999_999)
    |> Integer.to_string()
    |> String.pad_leading(@code_length, "0")
  end

  def expired?(%{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end
end
```

### Rate Limiting

```elixir
# Plug for rate limiting magic link requests
defmodule WrtWeb.Plugs.RateLimit do
  use PlugAttack

  rule "magic link requests", conn do
    if conn.path_info == ["org", _, "nominate", "request-link"] do
      # 5 requests per minute per IP
      throttle(conn.remote_ip, period: 60_000, limit: 5)
    end
  end
end
```

### Input Validation

```elixir
defmodule Wrt.People.Person do
  use Ecto.Schema
  import Ecto.Changeset

  schema "people" do
    field :name, :string
    field :email, :string
    field :source, Ecto.Enum, values: [:seed, :nominated]
    timestamps()
  end

  def changeset(person, attrs) do
    person
    |> cast(attrs, [:name, :email, :source])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)
    |> validate_length(:name, max: 255)
    |> unique_constraint(:email)
  end
end
```

## Testing Strategy

### Unit Tests

- Context functions (Campaigns, Rounds, People, etc.)
- Magic link generation and validation
- CSV/PDF export
- Email template rendering

### Integration Tests

- Full nomination flow (receive link → submit nominations)
- Round lifecycle (start → collect → close)
- Multi-tenant isolation (org A cannot see org B data)

### Example Test

```elixir
defmodule Wrt.RoundsTest do
  use Wrt.DataCase

  describe "start_round/2" do
    test "excludes previously contacted people" do
      tenant = create_tenant()
      campaign = create_campaign(tenant)

      # Round 1: contact Alice and Bob
      alice = create_person(tenant, email: "alice@example.com")
      bob = create_person(tenant, email: "bob@example.com")
      round1 = Rounds.start_round(tenant, campaign, [alice, bob])

      # Alice nominates Carol
      carol = create_person(tenant, email: "carol@example.com", source: :nominated)
      Rounds.close_round(tenant, round1)

      # Round 2: should only contact Carol, not Alice or Bob
      round2 = Rounds.start_round(tenant, campaign)
      contacts = Rounds.list_contacts(tenant, round2)

      assert length(contacts) == 1
      assert hd(contacts).person_id == carol.id
    end
  end
end
```

## Deployment

### Fly.io Configuration

```toml
# fly.toml
app = "wrt"
primary_region = "lhr"

[build]
  dockerfile = "Dockerfile"

[env]
  PHX_HOST = "wrt.example.com"
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true

  [[http_service.checks]]
    grace_period = "10s"
    interval = "30s"
    method = "GET"
    timeout = "5s"
    path = "/health"

[[services]]
  internal_port = 8080
  protocol = "tcp"

  [[services.ports]]
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443

[metrics]
  port = 9091
  path = "/metrics"
```

### Health Check Endpoints

All apps expose standardised health check endpoints (no authentication required):

| Endpoint | Purpose | Response |
|----------|---------|----------|
| `GET /health` | Liveness check | `200 {"status": "ok", "timestamp": "..."}` |
| `GET /health/ready` | Readiness check (includes DB connectivity) | `200 {"status": "ready", "checks": {"database": {"status": "ok"}}}` or `503` if unhealthy |

Fly.io's HTTP service health checks use `/health` to determine machine health. The CI pipeline also runs a post-deploy smoke test that curls `/health` with retries after each deployment.

### Environment Variables

```
DATABASE_URL=postgres://...
SECRET_KEY_BASE=...                       # Must match Portal's SECRET_KEY_BASE for cookie sharing
PHX_HOST=wrt.example.com
POSTMARK_API_KEY=...
PORTAL_API_URL=https://oostkit.com        # Portal base URL for auth validation
PORTAL_API_KEY=...                        # Same value as Portal's INTERNAL_API_KEY
PORTAL_LOGIN_URL=https://oostkit.com/users/log-in  # Redirect URL for unauthenticated users
```

### Release Configuration

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  database_url = System.fetch_env!("DATABASE_URL")

  config :wrt, Wrt.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))

  config :wrt, WrtWeb.Endpoint,
    url: [host: System.fetch_env!("PHX_HOST"), port: 443, scheme: "https"],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

  config :wrt, Wrt.Mailer,
    api_key: System.fetch_env!("POSTMARK_API_KEY")

  # Portal cross-app auth
  config :wrt, :portal_api_url, System.fetch_env!("PORTAL_API_URL")
  config :wrt, :portal_api_key, System.fetch_env!("PORTAL_API_KEY")
  config :wrt, :portal_login_url, System.fetch_env!("PORTAL_LOGIN_URL")
end
```

## Dependencies

```elixir
# mix.exs
defp deps do
  [
    {:oostkit_shared, path: "../oostkit_shared"},
    {:phoenix, "~> 1.7"},
    {:phoenix_ecto, "~> 4.4"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"},
    {:phoenix_html, "~> 4.0"},
    {:phoenix_live_reload, "~> 1.4", only: :dev},
    {:swoosh, "~> 1.14"},
    {:finch, "~> 0.16"},
    {:oban, "~> 2.17"},
    {:triplex, "~> 1.3"},
    {:bcrypt_elixir, "~> 3.1"},
    {:nimble_csv, "~> 1.2"},
    {:chromic_pdf, "~> 1.14"},
    {:plug_attack, "~> 0.4"},
    {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
    {:esbuild, "~> 0.8", runtime: Mix.env() == :dev}
  ]
end
```

The `oostkit_shared` path dependency provides shared Phoenix components used across all apps: `header_bar/1` (OOSTKit brand header used in the app layout) and `header/1` (page-level section header with title, subtitle, and actions slots).

## Implementation Phases

### Phase 1: Foundation ✓
- [x] Phoenix app scaffolding
- [x] Multi-tenancy setup with Triplex
- [x] Public schema migrations (orgs)
- [x] Tenant schema migrations
- [x] Portal-delegated authentication (RequirePortalUser)
- [x] Organisation management (via Portal, auto-resolved by admin email)
- [x] Landing page entry flow with "don't show again" option

### Phase 2: Core Campaign Flow ✓
- [x] Campaign CRUD
- [x] Seed group upload (CSV + manual)
- [x] Round management (start, close, extend)
- [x] Single-ask constraint enforcement

### Phase 3: Nomination Collection ✓
- [x] Magic link authentication (24hr tokens, 15min codes)
- [x] Nominator landing and verification flow
- [x] Nomination form with add/remove nominees
- [x] Edit nominations while round open
- [x] Convergence counting

### Phase 4: Email System ✓
- [x] Swoosh integration with Postmark/SendGrid
- [x] Invitation emails with magic links
- [x] Verification code emails
- [x] Webhook handlers for delivery/open/click tracking
- [x] Optional reminder emails (Oban worker)
- [x] Oban workers for async email sending

### Phase 5: Export & Reporting ✓
- [x] Reports context with campaign/round statistics
- [x] Convergence metrics (distribution, threshold)
- [x] Top nominees and nominators tracking
- [x] CSV export with filters (date range, rounds)
- [x] PDF report generation with ChromicPDF
- [x] Admin dashboard with real-time stats

### Phase 6: Polish & Operations ✓
- [x] Rate limiting (PlugAttack with configurable limits)
- [x] Health check endpoints (/health, /health/ready)
- [x] Structured logging for security events
- [x] Business telemetry events
- [x] Data retention check worker (24-month policy)
- [x] Magic link cleanup worker (expired tokens)
- [x] Comprehensive test suite (99 tests)
