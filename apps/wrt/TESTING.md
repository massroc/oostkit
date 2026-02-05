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

### Testing Email Flows

1. Start the app:
   ```bash
   cd apps/wrt
   docker compose up
   ```

2. Create test data through the admin UI:
   - Log in as super admin
   - Create an organisation
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

Production uses Postmark for real email delivery.

**Required secrets:**
```bash
fly secrets set POSTMARK_API_KEY=your-production-token -a your-prod-app
```

## Environment Variable Reference

| Variable | Values | Description |
|----------|--------|-------------|
| `MAIL_ADAPTER` | `logger`, `postmark` | Override default adapter |
| `POSTMARK_API_KEY` | API token | Postmark server token |

**Behavior:**
- If `MAIL_ADAPTER=logger` → logs emails (staging mode)
- If `POSTMARK_API_KEY` set → sends via Postmark
- If neither set → emails will fail (intentional, to catch misconfig)

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
