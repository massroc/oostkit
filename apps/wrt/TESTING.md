# WRT Testing Guide

This guide covers manual testing of email workflows in different environments.

## Local Development

### Email Capture

In development, all emails are captured locally using Swoosh's Local adapter. No emails are actually sent.

**View captured emails:**
```
http://localhost:4001/dev/mailbox
```

This mailbox shows all emails "sent" by the app, including:
- Round invitation emails (with magic links)
- Verification code emails
- Reminder emails
- Data retention warning emails (to org admins)

### Testing Email Flows

1. Start the app:
   ```bash
   cd apps/wrt
   docker compose up
   ```

2. Create test data through the UI:
   - Navigate to WRT at `http://localhost:4001`
   - In dev mode, the PortalAuth dev bypass auto-logs you in as `dev@oostkit.local`
   - Seeds create a "Dev Organisation" matched to that email, so you land on the landing page
   - Click through to the Process Manager (`/org/:slug/manage`)
   - Create a campaign and round
   - Add contacts to the round

3. Trigger email sends:
   - Send invitations from the round management page

4. View emails at `http://localhost:4001/dev/mailbox`

5. Click magic links directly from the mailbox preview - they work because they point to `localhost:4001`

### Testing Multiple Recipients

Since emails are captured locally (not actually sent), you can:
- Use any email address (real or fake like `test1@example.com`)
- All emails appear in the same dev mailbox
- Open multiple browser tabs/incognito windows to test different nominators

### Verification Codes

Verification code emails also appear in `/dev/mailbox`. Copy the 6-digit code from the email preview and paste it into the verification form.

## Staging Environment (Fly.io)

For staging deployments, you have two options:

### Option 1: Logger Adapter (Recommended for Staging)

Emails are logged to stdout instead of being sent. View them in Fly logs.

**Configuration:**
```bash
fly secrets set MAIL_ADAPTER=logger -a your-staging-app
```

**View emails:**
```bash
fly logs -a your-staging-app | grep -A 20 "Swoosh.Adapters.Logger"
```

The full email content (HTML and text) will be logged.

### Option 2: Separate Postmark Server

Use a dedicated Postmark "server" for staging. Emails appear in the Postmark dashboard.

1. In Postmark, create a new Server called "WRT Staging"
2. Get its Server API Token
3. Set it in Fly:
   ```bash
   fly secrets set POSTMARK_API_KEY=your-staging-token -a your-staging-app
   ```

Emails will be sent but you can monitor them in the Postmark dashboard.

## Production Environment

Production uses Postmark for real email delivery. All admin authentication is handled
by Portal — WRT has no login pages or password-based auth of its own.

**Required secrets:**
```bash
fly secrets set POSTMARK_API_KEY=your-production-token -a wrt-tool
fly secrets set SECRET_KEY_BASE=<same-as-portal> -a wrt-tool
fly secrets set PORTAL_API_KEY=<same-as-portal-internal-api-key> -a wrt-tool
fly secrets set PORTAL_API_URL=https://oostkit.com -a wrt-tool
fly secrets set PORTAL_LOGIN_URL=https://oostkit.com/users/log-in -a wrt-tool
```

## Environment Variable Reference

| Variable | Values | Description |
|----------|--------|-------------|
| `MAIL_ADAPTER` | `logger`, `postmark` | Override default adapter |
| `POSTMARK_API_KEY` | API token | Postmark server token |
| `PORTAL_API_URL` | URL | Portal base URL for auth validation |
| `PORTAL_API_KEY` | API key | Shared secret matching Portal's `INTERNAL_API_KEY` |
| `PORTAL_LOGIN_URL` | URL | Redirect URL for unauthenticated users |
| `SECRET_KEY_BASE` | Base64 string | Must match Portal's value for cookie sharing |

**Behavior:**
- If `MAIL_ADAPTER=logger` → logs emails (staging mode)
- If `POSTMARK_API_KEY` set → sends via Postmark
- If neither set → emails will fail (intentional, to catch misconfig)
- Portal auth variables are required in all environments (WRT has no native login)
- In dev/test, Portal auth defaults are configured in `config/dev.exs` and `config/test.exs`
- Portal must be running for WRT admin access (dev: `http://localhost:4002`)

## Rate Limiting

Rate limiting can be disabled via environment variable if needed for debugging:

```bash
fly secrets set RATE_LIMITER_ENABLED=false -a wrt-tool
```

To re-enable:
```bash
fly secrets set RATE_LIMITER_ENABLED=true -a wrt-tool
```

## Fly.io Deployment

The app is deployed to Fly.io as `wrt-tool`.

**Useful commands:**
```bash
# View status
fly status -a wrt-tool

# View logs
fly logs -a wrt-tool

# SSH into the machine
fly ssh console -a wrt-tool

# Run migrations manually
fly ssh console -a wrt-tool -C "/app/bin/migrate"
```

**Database:** `wrt-db` (PostgreSQL, 1GB RAM in syd region)
