# Workshop Referral Tool (WRT) - Solution Design

Technical architecture and implementation design for the OST Referral Tool.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Web Layer                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Super Admin │  │  Org Admin  │  │  Nominator (Public)     │  │
│  │   Routes    │  │   Routes    │  │       Routes            │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                     │                 │
│         ▼                ▼                     ▼                 │
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
│  │ - super_    │     │ - campaigns │      │ - campaigns │      │
│  │   admins    │     │ - rounds    │      │ - rounds    │      │
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
│   ├── application.ex              # OTP Application
│   │
│   ├── repo.ex                     # Ecto Repo
│   │
│   ├── tenant_manager.ex           # Multi-tenancy orchestration
│   │
│   ├── platform/                   # Public schema (cross-tenant)
│   │   ├── organisation.ex         # Schema
│   │   ├── super_admin.ex          # Schema
│   │   └── platform.ex             # Context
│   │
│   ├── orgs/                       # Org management (tenant-scoped)
│   │   ├── org_admin.ex            # Schema
│   │   └── orgs.ex                 # Context
│   │
│   ├── campaigns/                  # Campaign management
│   │   ├── campaign.ex             # Schema
│   │   ├── campaign_admin.ex       # Schema
│   │   └── campaigns.ex            # Context
│   │
│   ├── rounds/                     # Round management
│   │   ├── round.ex                # Schema
│   │   ├── contact.ex              # Schema (invitation tracking)
│   │   └── rounds.ex               # Context
│   │
│   ├── people/                     # People & nominations
│   │   ├── person.ex               # Schema
│   │   ├── nomination.ex           # Schema
│   │   └── people.ex               # Context
│   │
│   ├── auth/                       # Authentication
│   │   ├── magic_link.ex           # Schema
│   │   ├── session.ex              # Session management
│   │   └── auth.ex                 # Context
│   │
│   ├── mailer/                     # Email system
│   │   ├── mailer.ex               # Swoosh mailer
│   │   ├── templates/              # Email templates
│   │   │   ├── invitation.ex
│   │   │   ├── magic_link.ex
│   │   │   ├── reminder.ex
│   │   │   └── admin_summary.ex
│   │   └── tracker.ex              # Webhook handler for open/click
│   │
│   ├── export/                     # Export functionality
│   │   ├── csv_exporter.ex
│   │   └── pdf_report.ex
│   │
│   └── workers/                    # Oban workers
│       ├── send_invitation.ex
│       ├── send_reminder.ex
│       ├── close_round.ex
│       └── retention_cleanup.ex
│
├── wrt_web/
│   ├── router.ex
│   │
│   ├── plugs/
│   │   ├── tenant_plug.ex          # Extracts tenant from path
│   │   ├── require_super_admin.ex
│   │   ├── require_org_admin.ex
│   │   ├── require_campaign_admin.ex
│   │   └── require_nominator.ex
│   │
│   ├── controllers/
│   │   ├── super_admin/
│   │   │   ├── session_controller.ex
│   │   │   ├── org_controller.ex
│   │   │   └── dashboard_controller.ex
│   │   │
│   │   ├── org/
│   │   │   ├── session_controller.ex
│   │   │   ├── dashboard_controller.ex
│   │   │   ├── campaign_controller.ex
│   │   │   ├── round_controller.ex
│   │   │   ├── people_controller.ex
│   │   │   └── export_controller.ex
│   │   │
│   │   ├── nominator/
│   │   │   ├── auth_controller.ex    # Magic link flow
│   │   │   └── nomination_controller.ex
│   │   │
│   │   ├── registration_controller.ex  # Org registration
│   │   │
│   │   └── webhook_controller.ex       # Email tracking webhooks
│   │
│   ├── components/                   # Phoenix components
│   │   ├── layouts.ex
│   │   └── core_components.ex
│   │
│   └── templates/                    # EEx templates
│       ├── layouts/
│       ├── super_admin/
│       ├── org/
│       └── nominator/
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
- `priv/repo/migrations/` - Public schema (organisations, super_admins)
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
# Public routes
GET  /                                    # Landing page
GET  /register                            # Org registration form
POST /register                            # Submit registration

# Super admin routes
GET  /admin/login                         # Super admin login
POST /admin/login
GET  /admin/dashboard                     # Platform overview
GET  /admin/orgs                          # Pending/approved orgs
POST /admin/orgs/:id/approve
POST /admin/orgs/:id/reject
POST /admin/orgs/:id/suspend

# Org-scoped routes (tenant context)
GET  /org/:slug/login                     # Org admin login
POST /org/:slug/login
GET  /org/:slug/dashboard                 # Campaign overview
GET  /org/:slug/campaigns/new             # Create campaign
POST /org/:slug/campaigns
GET  /org/:slug/campaigns/:id             # Campaign detail
GET  /org/:slug/campaigns/:id/seed        # Manage seed group
POST /org/:slug/campaigns/:id/seed/upload # CSV upload
GET  /org/:slug/campaigns/:id/rounds      # Round management
POST /org/:slug/campaigns/:id/rounds      # Start new round
GET  /org/:slug/campaigns/:id/rounds/:num # Round detail
POST /org/:slug/campaigns/:id/rounds/:num/close
POST /org/:slug/campaigns/:id/rounds/:num/extend
GET  /org/:slug/campaigns/:id/results     # Convergence view
GET  /org/:slug/campaigns/:id/export/csv  # Download CSV
GET  /org/:slug/campaigns/:id/export/pdf  # Download PDF

# Nominator routes (public, token-authenticated)
GET  /org/:slug/nominate/:token           # Landing with magic link
POST /org/:slug/nominate/request-link     # Request magic link email
GET  /org/:slug/nominate/verify/:code     # Verify magic link code
GET  /org/:slug/nominate/form             # Nomination form (authenticated)
POST /org/:slug/nominate/submit           # Submit nominations

# Webhook routes
POST /webhooks/email/:provider            # Email tracking callbacks
```

## Authentication Flows

### Super Admin Authentication

Standard email/password with session cookie.

```elixir
defmodule Wrt.Auth do
  def authenticate_super_admin(email, password) do
    case Platform.get_super_admin_by_email(email) do
      nil -> {:error, :not_found}
      admin ->
        if Bcrypt.verify_pass(password, admin.password_hash) do
          {:ok, admin}
        else
          {:error, :invalid_password}
        end
    end
  end
end
```

### Org/Campaign Admin Authentication

Email/password, scoped to tenant.

```elixir
def authenticate_org_admin(tenant, email, password) do
  case Orgs.get_admin_by_email(tenant, email) do
    nil -> {:error, :not_found}
    admin ->
      if Bcrypt.verify_pass(password, admin.password_hash) do
        {:ok, admin}
      else
        {:error, :invalid_password}
      end
  end
end
```

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

# Data retention cleanup (runs daily)
defmodule Wrt.Workers.RetentionCleanup do
  use Oban.Worker, queue: :maintenance

  @impl true
  def perform(_job) do
    cutoff = DateTime.utc_now() |> DateTime.add(-24 * 30, :day)  # 24 months
    warning_cutoff = DateTime.utc_now() |> DateTime.add(-23 * 30, :day)  # 23 months

    # Send warnings for campaigns approaching deletion
    Campaigns.list_completed_before(warning_cutoff)
    |> Enum.each(&send_deletion_warning/1)

    # Delete campaigns past retention period
    Campaigns.list_completed_before(cutoff)
    |> Enum.each(&Campaigns.delete_campaign/1)

    :ok
  end
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

### Environment Variables

```
DATABASE_URL=postgres://...
SECRET_KEY_BASE=...
PHX_HOST=wrt.example.com
POSTMARK_API_KEY=...
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
end
```

## Dependencies

```elixir
# mix.exs
defp deps do
  [
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

## Implementation Phases

### Phase 1: Foundation
- Phoenix app scaffolding
- Multi-tenancy setup with Triplex
- Public schema migrations (orgs, super_admins)
- Tenant schema migrations
- Super admin authentication
- Org registration flow

### Phase 2: Core Campaign Flow
- Org admin authentication
- Campaign CRUD
- Seed group upload (CSV + manual)
- Round management (start, close, extend)
- Single-ask constraint enforcement

### Phase 3: Nomination Collection
- Magic link authentication
- Nomination form
- Edit nominations while round open
- Convergence counting

### Phase 4: Email System
- Swoosh integration with Postmark
- Invitation emails
- Magic link emails
- Webhook handlers for tracking
- Optional reminder emails

### Phase 5: Export & Reporting
- CSV export with filters
- PDF report generation
- Admin dashboard stats

### Phase 6: Polish & Operations
- Rate limiting
- Error handling and logging
- Data retention jobs
- Monitoring and metrics
