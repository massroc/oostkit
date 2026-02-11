# Workshop Referral Tool (WRT) Requirements

A web-based tool for managing participative referral processes based on Open Systems Theory (OST) methodology. The tool supports the selection of workshop participants through network-based nomination, letting the system surface its own participants rather than having them chosen by a single authority.

## Implementation Status

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1: Foundation | ✅ Complete | Multi-tenancy, auth, org registration |
| Phase 2: Campaign Flow | ✅ Complete | Campaigns, rounds, seed groups |
| Phase 3: Nomination | ✅ Complete | Magic links, nomination form |
| Phase 4: Email System | ✅ Complete | Invitations, webhooks, reminders |
| Phase 5: Export | ✅ Complete | CSV/PDF export, reporting |
| Phase 6: Operations | ✅ Complete | Rate limiting, health checks, logging |

**Test Coverage:** 99 tests across contexts, controllers, workers, and emails

## Background

### The Referral Process (OST)

The referral method is participative by nature—it lets the system identify its own participants:

1. Start with a known group (e.g., board and senior leaders)
2. Ask them to nominate others who should be involved
3. Ask the nominated people who else should be there
4. Iterate through the network until the system surfaces its own participants
5. Multiple nominations for the same person (convergence) signals inclusion

**Key constraints:**
- Each person is asked only once, regardless of how many rounds run
- Rounds function like a wavefront moving through the network
- Target participant count: typically 15-25 for a PDW

## User Roles

### Super Admin
- You (the platform owner)
- Approves/rejects organisation registration requests
- Can suspend organisations
- Views platform-wide metrics

### Organisation Admin
- Creates and manages campaigns for their organisation
- Invites campaign admins
- Manages organisation settings
- Views all campaigns for their org

### Campaign Admin
- Invited collaborator on a specific campaign
- Can manage rounds, view nominations, export data
- Cannot create new campaigns or manage org settings

### Nominator
- Receives invitation email with magic link
- Submits nominations (name + email for each)
- Can edit nominations until round closes
- No account required—authenticated via magic link

## Core Concepts

### Organisation (Tenant)
A self-contained entity with strict data isolation. Each organisation:
- Has its own schema in the database
- Manages its own people, campaigns, and admins
- Can run one active campaign at a time

### Campaign
A single referral process for selecting workshop participants. Contains:
- Configuration (name, description, round duration)
- Multiple rounds
- Seed group (initial invitees)
- Accumulated nominations and convergence data

### Round
A phase of the referral process:
- Has a deadline (time-based, with manual override)
- Sends invitations to eligible people
- Collects nominations
- Auto-closes at deadline or can be manually closed/extended

### Person
Anyone known to the system within an organisation:
- Unique identifier: email address
- Source: seed (initial upload) or nominated (added during process)
- Tracks: contacted (yes/no), which round, response status

### Nomination
A record of one person nominating another:
- Who nominated (nominator)
- Who was nominated (nominee)
- Which round
- Timestamp

## Features

### F1: Organisation Management

#### F1.1: Organisation Registration
- Prospective org admins submit registration request
- Request includes: org name, admin name, admin email, brief description
- Super admin receives notification of pending requests
- Super admin approves or rejects with optional message
- On approval: org schema created, admin account activated, welcome email sent

#### F1.2: Organisation Settings
- Org admins can update organisation name and details
- Org admins can invite additional org admins
- Org admins can view/manage campaign admins across campaigns

#### F1.3: Organisation Suspension
- Super admin can suspend an organisation
- Suspended orgs cannot run campaigns or send emails
- Existing data preserved, access restricted

### F2: Campaign Management

#### F2.1: Create Campaign
- Org admin creates new campaign (only if no active campaign exists)
- Required fields: name, description
- Optional fields: target participant count, default round duration
- Campaign starts in "draft" status

#### F2.2: Seed Group Setup
- Upload CSV with initial group (name, email, optional role)
- Manual entry form to add individuals
- Validation: email format, duplicate detection
- Preview before confirming seed group

#### F2.3: Campaign Lifecycle
- Draft → Active → Completed
- Cannot delete active campaign (must complete or archive)
- Completed campaigns remain viewable for export/reference

### F3: Round Management

#### F3.1: Start Round
- First round: invites seed group
- Subsequent rounds: invites people nominated in previous round who haven't been contacted
- Set round deadline (default from campaign settings, adjustable)
- Preview recipient list before sending

#### F3.2: Round Progress
- View response rate: invited vs. submitted
- View pending (invited, not yet responded)
- View nominations collected this round
- Email tracking: opens and clicks

#### F3.3: Round Control
- Extend deadline
- Close round early (manual override)
- Round auto-closes at deadline
- Optional reminder email: admins can enable a reminder sent X days before deadline

#### F3.4: Single-Ask Constraint
- System automatically excludes anyone previously contacted
- Visual indication of who will/won't be contacted in next round
- Cannot override—this is a core OST principle

### F4: Nomination Collection ✅

#### F4.1: Nominator Authentication ✅
- ✅ Invitation email contains unique magic link (24-hour validity)
- ✅ Clicking link sends login code to email (6-digit code)
- ✅ Code valid for limited time (15 minutes)
- ✅ Session persists until round closes

#### F4.2: Nomination Form ✅
- ✅ Nominator sees: campaign description, what they're being asked
- ✅ Structured input: name + email for each nominee
- ✅ Add multiple nominees (no fixed limit)
- ✅ Validation: email format required

#### F4.3: Edit Nominations ✅
- ✅ Nominator can return via magic link while round is open
- ✅ Add, remove, or modify nominations
- ✅ Changes tracked (latest submission used for counting)

#### F4.4: Confirmation ✅
- ✅ Clear confirmation when nominations submitted
- ✅ Summary of who they nominated
- ✅ Note that they won't be asked again

### F5: Convergence Tracking

#### F5.1: Real-time Counts
- Dashboard shows nomination counts per person
- Updates as nominations come in
- Sortable by count (highest first)

#### F5.2: Convergence Visualisation
- List view: name, email, count, which rounds nominated
- Highlight threshold (e.g., 2+ nominations)
- Show new people (not in seed group)

#### F5.3: Network View (Future Enhancement)
- Visual graph of who nominated whom
- Identify clusters and bridges
- Not required for MVP

### F6: Export and Reporting ✅

#### F6.1: CSV Export ✅
- ✅ Columns: name, email, nomination_count
- ✅ Filterable: all people, by date range, by round
- ✅ Download at any point during or after campaign

#### F6.2: PDF Report ✅
- ✅ Campaign summary: name, org, dates, rounds completed
- ✅ Statistics: total people contacted, response rate, nominations collected
- ✅ Candidate list: sorted by convergence count
- ✅ Generated on demand (ChromicPDF)

### F7: Email System ✅

#### F7.1: Email Templates ✅
- ✅ Invitation email with magic link
- ✅ Verification code email
- ✅ Round reminder (optional, Oban worker)
- ✅ Data retention warning email (to org admins, with campaign name, deletion date, days remaining)
- Campaign completion summary (to admins) - *planned*

#### F7.2: Email Delivery ✅
- ✅ Integration with transactional email service (Postmark/SendGrid)
- ✅ Swoosh adapter for email abstraction
- ✅ Oban workers for async sending

#### F7.3: Email Tracking ✅
- ✅ Track: sent, delivered, opened, clicked, bounced, spam
- ✅ Webhook handlers for Postmark and SendGrid
- ✅ Aggregate stats per round (Reports context)

### F8: Admin Authentication

#### F8.1: Super Admin
- Standard email/password login (WRT-native, retained during transition)
- Portal cross-app authentication: reads `_oostkit_token` cookie, validates against Portal's internal API
- Transitional: either WRT-native super admin session OR Portal super_admin role grants access
- Protected routes for platform management

#### F8.2: Portal Integration
- `PortalAuthClient` calls Portal's `POST /api/internal/auth/validate` endpoint
- Results cached in ETS with 5-minute TTL (avoids per-request HTTP calls)
- `PortalAuth` plug reads `_oostkit_token` cookie and sets `:portal_user` assign on conn
- `RequirePortalOrWrtSuperAdmin` plug accepts either auth method during migration
- Config: `portal_api_url`, `portal_api_key`, `portal_login_url`

#### F8.3: Org and Campaign Admins
- Email/password login
- Scoped to their organisation's schema
- Role-based access (org admin vs. campaign admin)

## Data Model

### Platform Schema (shared)

```
organisations
- id
- name
- schema_name (unique identifier for tenant schema)
- status (pending, approved, suspended)
- created_at
- approved_at
- approved_by (super_admin_id)

super_admins
- id
- email
- password_hash
- name
```

### Per-Organisation Schema

```
org_admins
- id
- email
- password_hash
- name
- inserted_at

campaigns
- id
- name
- description
- status (draft, active, completed)
- default_round_duration_days
- target_participant_count
- inserted_at
- started_at
- completed_at

campaign_admins
- id
- campaign_id
- email
- password_hash
- name
- invited_by (org_admin_id)
- inserted_at

rounds
- id
- campaign_id
- round_number
- status (pending, active, closed)
- deadline
- started_at
- closed_at

people
- id
- email (unique within org)
- name
- source (seed, nominated)
- inserted_at

contacts
- id
- person_id
- round_id
- invited_at
- email_status (pending, sent, delivered, opened, clicked, bounced, spam)
- responded_at

nominations
- id
- round_id
- nominator_id (person_id)
- nominee_id (person_id)
- inserted_at

magic_links
- id
- person_id
- round_id
- token (unique)
- expires_at
- used_at
```

## Technical Requirements

### T1: Multi-tenancy
- Schema-per-tenant isolation using PostgreSQL schemas
- Path-based routing: `wrt.example.com/org/orgname`
- Tenant identified by URL path and session context
- Migrations run against all tenant schemas

### T2: Stack
- Elixir/Phoenix (server-rendered, no LiveView for MVP)
- PostgreSQL with schema-per-tenant
- Tailwind CSS for styling

### T3: Email Integration
- Swoosh for email abstraction
- Adapter for Postmark or Sendgrid
- Webhook endpoints for delivery/open/click tracking

### T4: Deployment
- Fly.io (consistent with other apps in monorepo)
- Environment-based configuration for email service credentials

### T5: Security
- Magic links expire after use and after time limit
- Admin passwords hashed with bcrypt/argon2
- HTTPS only
- CSRF protection on all forms

## Non-Functional Requirements

### Performance
- Support 50+ concurrent nominators per campaign
- Email sends queued and processed asynchronously
- Page loads under 500ms

### Reliability
- Email delivery failures logged and retryable
- Database backups (Fly.io managed)

### Usability
- Mobile-friendly nomination form
- Clear progress indicators for admins
- Accessible (WCAG 2.1 AA)

### Data Retention ✅
- Completed campaign data auto-deleted after 24 months
- ✅ Orgs notified before deletion (30 days warning via email to all org admins)
- Export available before deletion deadline

## Out of Scope (MVP)

- Network visualisation (who nominated whom graph)
- Custom email domains per org
- API access for integrations
- Billing/payments
- White-labelling (custom logos, colours per org)

