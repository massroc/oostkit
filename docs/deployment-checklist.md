# Deployment Checklist

Step-by-step guide to deploying OOSTKit applications to production.

## Prerequisites

- [ ] Fly.io CLI installed (`curl -L https://fly.io/install.sh | sh`)
- [ ] Fly.io account created (`fly auth signup`)
- [ ] Domain name purchased

## Domain Setup

### Purchase Domain

- [ ] Choose domain name (e.g., `oostkit.com`, `oostkit.io`)
- [ ] Purchase from registrar (Namecheap, Cloudflare, Google Domains, etc.)
- [ ] Verify ownership via email confirmation

### Domain Strategy

| Domain | Purpose |
|--------|---------|
| `oostkit.com` | Main landing/portal |
| `pulse.oostkit.com` | Workgroup Pulse app |
| `wrt.oostkit.com` | Workshop Referral Tool |

Alternative: Use root domain for the primary app if no portal needed initially.

## Workgroup Pulse Deployment

### Create Fly.io App

```bash
cd apps/workgroup_pulse

# Create the app
fly apps create workgroup-pulse

# Verify creation
fly apps list
```

### Create PostgreSQL Database

```bash
# Create database cluster (Sydney region)
fly postgres create \
  --name workgroup-pulse-db \
  --region syd \
  --vm-size shared-cpu-1x \
  --initial-cluster-size 1 \
  --volume-size 1

# Attach to app (automatically sets DATABASE_URL secret)
fly postgres attach workgroup-pulse-db --app workgroup-pulse
```

- [ ] Database created
- [ ] Database attached to app

### Set Application Secrets

```bash
# Generate and set secret key base
fly secrets set SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')

# Verify secrets are set
fly secrets list
```

- [ ] SECRET_KEY_BASE set

### Update Configuration

Update `apps/workgroup_pulse/fly.toml`:

```toml
app = "workgroup-pulse"

[env]
  PHX_HOST = "pulse.oostkit.com"  # or your domain
```

- [ ] `fly.toml` updated with correct app name
- [ ] `fly.toml` updated with correct PHX_HOST

### Deploy

```bash
# Deploy the app
fly deploy

# Check status
fly status

# View logs
fly logs
```

- [ ] Initial deployment successful
- [ ] Health checks passing

### Configure Custom Domain

```bash
# Get IP addresses
fly ips list

# Add SSL certificate for domain
fly certs add pulse.oostkit.com

# Check certificate status
fly certs show pulse.oostkit.com
```

- [ ] IP addresses noted
- [ ] SSL certificate requested

### DNS Configuration

Add these records at your domain registrar:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | pulse | `<IPv4 from fly ips list>` | 300 |
| AAAA | pulse | `<IPv6 from fly ips list>` | 300 |

- [ ] DNS A record added
- [ ] DNS AAAA record added
- [ ] SSL certificate issued (check with `fly certs show`)
- [ ] Site accessible via custom domain

## CI/CD Setup (GitHub Actions)

### Generate Fly.io Deploy Token

```bash
# Create a deploy token
fly tokens create deploy -x 999999h

# Copy the token value
```

### Add GitHub Secret

1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `FLY_API_TOKEN`
4. Value: (paste token from above)

- [ ] Deploy token generated
- [ ] GitHub secret `FLY_API_TOKEN` added

### Verify CI/CD

1. Push a change to `apps/workgroup_pulse/` on main branch
2. Check GitHub Actions for successful deployment

- [ ] CI/CD pipeline deploying successfully

## Cross-App Auth Secrets

Portal and WRT (and future apps) require coordinated secrets for cross-app authentication.

### Portal Secrets

```bash
# Generate a shared secret key base (MUST be the same across all apps)
fly secrets set SECRET_KEY_BASE=<shared-value> -a oostkit-portal

# Internal API key for cross-app token validation
fly secrets set INTERNAL_API_KEY=$(openssl rand -base64 32 | tr -d '\n') -a oostkit-portal

# Cookie domain for subdomain-scoped cookies
fly secrets set COOKIE_DOMAIN=.oostkit.com -a oostkit-portal

# Postmark API key for email delivery
fly secrets set POSTMARK_API_KEY=<postmark-token> -a oostkit-portal
```

- [ ] `SECRET_KEY_BASE` set (shared with WRT)
- [ ] `INTERNAL_API_KEY` set
- [ ] `COOKIE_DOMAIN` set to `.oostkit.com`
- [ ] `POSTMARK_API_KEY` set

### WRT Secrets

```bash
# Same SECRET_KEY_BASE as Portal
fly secrets set SECRET_KEY_BASE=<same-shared-value> -a wrt-tool

# Portal API key (same value as Portal's INTERNAL_API_KEY)
fly secrets set PORTAL_API_KEY=<same-as-internal-api-key> -a wrt-tool
```

- [ ] `SECRET_KEY_BASE` matches Portal's value
- [ ] `PORTAL_API_KEY` matches Portal's `INTERNAL_API_KEY`

## Future Apps (WRT, etc.)

Repeat the process for each new app:

1. [ ] Create Fly.io app: `fly apps create <app-name>`
2. [ ] Create or attach database
3. [ ] Set secrets (including `SECRET_KEY_BASE` matching Portal, and `PORTAL_API_KEY` if using Portal auth)
4. [ ] Configure `fly.toml`
5. [ ] Deploy: `fly deploy`
6. [ ] Add subdomain certificate
7. [ ] Configure DNS

## Portal Deployment

Portal is a Phoenix app deployed on Fly.io as `oostkit-portal`. It serves as the authentication hub and landing page.

**CI/CD:** Portal has automated deployment enabled via GitHub Actions. Merges to main automatically deploy to Fly.io.

**Build Context:** Portal's `Dockerfile` uses the **monorepo root** as the build context (not `apps/portal/`). This allows the build to access `shared/tailwind.preset.js` during asset compilation. The CI workflow deploys from the root directory with `fly deploy --config apps/portal/fly.toml --dockerfile apps/portal/Dockerfile`.

```bash
cd apps/portal

# Create the app
fly apps create oostkit-portal

# Create database
fly postgres create --name oostkit-portal-db --region syd --vm-size shared-cpu-1x --initial-cluster-size 1 --volume-size 1
fly postgres attach oostkit-portal-db --app oostkit-portal

# Set secrets (see "Cross-App Auth Secrets" section above for auth-specific secrets)
fly secrets set SECRET_KEY_BASE=<shared-value> -a oostkit-portal
fly secrets set INTERNAL_API_KEY=<generated-key> -a oostkit-portal
fly secrets set COOKIE_DOMAIN=.oostkit.com -a oostkit-portal
fly secrets set POSTMARK_API_KEY=<postmark-token> -a oostkit-portal

# Deploy manually (or let CI handle it)
# NOTE: Must deploy from monorepo root
cd ../..
fly deploy --config apps/portal/fly.toml --dockerfile apps/portal/Dockerfile
```

**Production Configuration:**
- `config/prod.exs` configures Swoosh to use `Swoosh.ApiClient.Finch` instead of hackney for Postmark email delivery

- [ ] Portal app created on Fly.io
- [ ] Portal database created and attached
- [ ] Portal secrets set (including cross-app auth secrets)
- [ ] Portal deployed (tool catalogue is seeded automatically via data migration -- no manual seed step required)
- [ ] Root domain (`oostkit.com`) configured and SSL certificate issued
- [x] CI/CD enabled (auto-deploys on merge to main)
- [x] `.dockerignore` configured to exclude other apps from build context
- [x] Dockerfile uses monorepo root build context for shared design system access

## Monitoring & Maintenance

### Fly.io Dashboard

- View at: https://fly.io/dashboard

### Useful Commands

```bash
# View app status
fly status -a workgroup-pulse

# View logs
fly logs -a workgroup-pulse

# SSH into running machine
fly ssh console -a workgroup-pulse

# Run migrations manually
fly ssh console -a workgroup-pulse -C "/app/bin/migrate"

# Scale app
fly scale count 2 -a workgroup-pulse

# View metrics
fly dashboard -a workgroup-pulse
```

### Database Maintenance

```bash
# Connect to database
fly postgres connect -a workgroup-pulse-db

# View database status
fly status -a workgroup-pulse-db
```

## Cost Summary

| Resource | Estimated Cost |
|----------|----------------|
| Fly.io shared-cpu-1x VM (1GB) | ~$5-7/month |
| Fly.io PostgreSQL (1GB) | ~$7/month |
| Domain name | ~$10-15/year |
| SSL certificates | Free (via Fly.io) |
| **Total per app** | **~$12-15/month** |

Note: Costs may vary. Check [Fly.io pricing](https://fly.io/docs/about/pricing/) for current rates.

## Troubleshooting

### App won't start

```bash
# Check logs for errors
fly logs -a workgroup-pulse

# Check machine status
fly machine list -a workgroup-pulse
```

### Database connection issues

```bash
# Verify DATABASE_URL is set
fly secrets list -a workgroup-pulse

# Test database connectivity
fly postgres connect -a workgroup-pulse-db
```

### SSL certificate pending

- DNS propagation can take up to 48 hours
- Verify DNS records with: `dig pulse.oostkit.com`
- Check certificate status: `fly certs show pulse.oostkit.com`
