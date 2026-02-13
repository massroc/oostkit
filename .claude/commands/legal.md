Audit code and configuration for Australian legal compliance requirements.

Usage:
- `/legal` — general compliance posture review of the platform
- `/legal privacy <app>` — audit data privacy compliance (Privacy Act / GDPR)
- `/legal terms` — review terms of service and consent implementation
- `/legal emails <app>` — audit email sending against the Spam Act 2003
- `/legal licensing` — audit open source dependency licences
- `/legal risk <topic>` — assess legal risk for a specific area

If no argument is given, default to general compliance posture review.

## Step 1: Determine mode

Parse `$ARGUMENTS`:

- **Blank** → **Posture review** mode
- **"privacy"** followed by app name → **Privacy audit** mode
- **"terms"** → **Terms audit** mode
- **"emails"** followed by app name → **Email compliance** mode
- **"licensing"** → **Licence audit** mode
- **"risk"** followed by a topic → **Risk assessment** mode

## Step 2: Load context

**Always read:**
- `docs/product-vision.md` — what the platform does and who it serves
- `docs/architecture.md` — how apps relate to each other

**Per mode, also read:**

**Privacy audit:**
- The app's Ecto schemas (Glob for `use Ecto.Schema`)
- The app's `endpoint.ex` — filter_parameters, session config
- `config/runtime.exs` — database SSL, secrets
- The app's `REQUIREMENTS.md` — documented data practices

**Terms audit:**
- Search for terms/ToS acceptance tracking: Grep for `terms`, `tos`, `accept`, `consent` in schemas and migrations
- The app's registration/signup flow (LiveView or controller)
- Any privacy policy or terms content files

**Email compliance:**
- Grep for email sending: `Swoosh`, `Mailer`, `deliver`, `send_email` across the app
- Email template files
- Any unsubscribe endpoint or preference management

**Licence audit:**
- Root `mix.lock` — all Hex dependencies
- Any `package.json` files — JS dependencies
- `LICENSE` file at repo root
- Third-party asset files (fonts, icons)

---

## Mode: Posture review

Survey compliance readiness across all key areas. For each area, assess as:
- **Compliant** — requirements met
- **Partial** — some requirements met, gaps identified
- **Non-compliant** — requirements not met
- **Not assessed** — insufficient information to determine

### Privacy (Privacy Act 1988 / APPs)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Privacy policy accessible (APP 1) | | Check for public URL, currency |
| Collection is minimised (APP 3) | | Check schemas for unnecessary fields |
| Collection notice exists (APP 5) | | Check signup flow for notice |
| No secondary use without basis (APP 6) | | Check for analytics, marketing use |
| Technical security measures (APP 11) | | Encryption, TLS, access controls |
| Data destruction when not needed (APP 11) | | Check for retention/deletion mechanisms |
| User access mechanism (APP 12) | | Check for data export capability |
| User correction mechanism (APP 13) | | Check for profile editing |

### Notifiable Data Breaches (Privacy Act Part IIIC)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Passwords hashed with bcrypt/argon2 | | Check accounts context |
| Force SSL in production | | Check endpoint config |
| CSRF protection enabled | | Check router pipelines |
| Session cookie secure and httponly | | Check session config |
| Failed login logging | | Check auth handlers |
| Force password reset capability | | Check admin functions |
| Mass notification capability | | Check email infrastructure |
| Breach response documented | | Check for incident response docs |

### Spam Act 2003

| Requirement | Status | Notes |
|-------------|--------|-------|
| Marketing consent separate from ToS | | Check signup flow |
| Unsubscribe mechanism | | Check email templates |
| Sender identification in emails | | Check email templates |
| Transactional vs marketing classified | | Check email sending code |

### Disability Discrimination Act 1992

| Requirement | Status | Notes |
|-------------|--------|-------|
| WCAG 2.1 AA targeted | | Check templates for semantic HTML |
| Keyboard navigable | | Check for interactive elements |
| Screen reader compatible | | Check for ARIA usage |
| (Suggest `/accessibility audit <app>` for detailed review) | | |

### Australian Consumer Law

| Requirement | Status | Notes |
|-------------|--------|-------|
| Terms of service exist | | Check for ToS content |
| No unfair contract terms | | Review ToS content |
| Cancellation is self-service | | Check account management |
| Pricing transparent | | Check pricing display |

### Open source licensing

| Requirement | Status | Notes |
|-------------|--------|-------|
| No AGPL dependencies | | Check mix.lock |
| LICENSE file exists | | Check repo root |
| Attribution provided | | Check NOTICE file or about page |

### Summary table

| Area | Status | Priority action |
|------|--------|----------------|
| Privacy | | |
| Data breach prevention | | |
| Spam Act | | |
| Accessibility (DDA) | | |
| Consumer law | | |
| Licensing | | |

---

## Mode: Privacy audit

Deep audit of data privacy compliance for a specific app.

### Data inventory

Map all personal data:

| Schema | Field | Data type | Classification | Purpose | Retention | Legal basis |
|--------|-------|-----------|---------------|---------|-----------|-------------|
| User | email | PII | Confidential | Authentication | Account lifetime | Contract |
| User | name | PII | Confidential | Display | Account lifetime | Contract |

### APP-by-APP assessment

For each applicable Australian Privacy Principle, assess compliance:

**APP 1 — Transparency:** Is there an accessible, current privacy policy?
**APP 3 — Collection:** Is every field reasonably necessary? Is sensitive data consented?
**APP 5 — Notice:** Are users notified at collection about purpose, recipients, consequences?
**APP 6 — Use/disclosure:** Is data used only for primary purpose?
**APP 8 — Cross-border:** If data goes overseas (cloud hosting, third-party APIs), is this documented?
**APP 11 — Security:** Encryption, access controls, destruction when no longer needed?
**APP 12 — Access:** Can users get a copy of their data?
**APP 13 — Correction:** Can users correct their data?

### GDPR considerations (if international users)

- Lawful basis documented per processing purpose
- Data subject rights implementable (access, rectification, erasure, portability)
- Cookie consent for EU visitors
- Cross-border transfer mechanism (SCCs if data leaves AU/EU)

---

## Mode: Email compliance

Audit email sending against the Spam Act 2003.

### Email classification

For each email type found in the codebase:

| Email | Type | Consent required? | Unsubscribe required? |
|-------|------|-------------------|----------------------|
| Password reset | Transactional | No | No |
| Welcome email | Transactional | No | No |
| Workshop invitation | Transactional (service delivery) | No | No |
| Feature announcement | Commercial/marketing | Yes | Yes |
| Newsletter | Commercial/marketing | Yes | Yes |

### Compliance checks

| Check | Requirement |
|-------|-------------|
| Consent capture | Marketing opt-in recorded with timestamp, separate from ToS acceptance |
| Consent checkbox default | Unchecked by default (not pre-ticked) |
| Unsubscribe link | Every marketing email contains a working unsubscribe link |
| Unsubscribe processing | Processed within 5 business days (must be immediate in code) |
| Sender identification | Emails include: sender name, ABN or contact details |
| List-Unsubscribe header | Set on marketing emails |
| Exclusion of unsubscribed | Unsubscribed users excluded from marketing sends |

---

## Mode: Licence audit

Audit dependency licences for compliance.

### Process

1. Parse `mix.lock` to list all Hex dependencies
2. For each, check the licence (most Hex packages declare this in `mix.exs`)
3. Flag any issues:

| Licence | Risk | Action |
|---------|------|--------|
| MIT, Apache-2.0, BSD | None | Include attribution |
| LGPL | Low | Modifications to the library must be shared |
| GPL | Medium | Copyleft may propagate — review usage |
| **AGPL** | **High** | SaaS must offer source code — likely incompatible |
| No licence | High | Cannot legally use — contact maintainer or replace |

### Output

| Dependency | Version | Licence | Risk | Action needed |
|-----------|---------|---------|------|---------------|
| phoenix | 1.7.x | MIT | None | Attribution |
| ecto | 3.x | Apache-2.0 | None | Attribution |

---

## Mode: Risk assessment

Assess legal risk for a specific topic using a severity-by-likelihood framework.

### Framework

**Severity** (1-5): Negligible → Low → Moderate → High → Critical
**Likelihood** (1-5): Remote → Unlikely → Possible → Likely → Almost certain
**Risk score** = Severity x Likelihood

| Score | Level | Action |
|-------|-------|--------|
| 1-4 | GREEN | Accept and monitor |
| 5-9 | YELLOW | Mitigate, assign owner, monitor actively |
| 10-15 | ORANGE | Escalate to senior counsel, develop mitigation plan |
| 16-25 | RED | Immediate action, consider outside counsel |

### Output format

```
## Legal Risk Assessment: [topic]

**Severity:** [1-5] — [label]
[Rationale]

**Likelihood:** [1-5] — [label]
[Rationale]

**Risk Score:** [score] — [GREEN/YELLOW/ORANGE/RED]

### Contributing factors
- [factor 1]
- [factor 2]

### Mitigating factors
- [factor 1]
- [factor 2]

### Recommended actions
1. [action — owner — timeline]
2. [action — owner — timeline]

### Residual risk after mitigation
[Expected risk level]
```

---

## Important note

This skill assists with identifying legal compliance considerations in code and configuration. It does NOT provide legal advice. Compliance determinations should be reviewed by a qualified Australian legal practitioner. Regulatory requirements change — always verify current requirements with authoritative sources.

Australian legislation referenced:
- Privacy Act 1988 (Cth) — Australian Privacy Principles, Notifiable Data Breaches
- Spam Act 2003 (Cth) — commercial electronic messages
- Disability Discrimination Act 1992 (Cth) — web accessibility
- Competition and Consumer Act 2010 (Cth), Schedule 2 — Australian Consumer Law
- Electronic Transactions Act 1999 (Cth) — validity of electronic records
