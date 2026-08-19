# bloanc

Mortgage offer comparison app for Polish PLN home loans.

## Product Summary
- Compare active bank offers with realistic total costs, not only base installment.
- Include margin, WIBOR, commission, life/property insurance, and overpayment penalty impact.
- Support two interest-rate offer types: variable and fixed-period-then-variable.
- Let users simulate overpayment strategies on the homepage.
- Let admins manage banks, offers, and WIBOR snapshots.

## Current Functionality

### Public Homepage
- Locale-aware UI: PL (default), EN, UA.
- Separate public URLs per locale + rate type (localized slugs).
- Inputs:
    - Loan amount: number input + slider
    - Loan period in years: number input + slider
- Loan type tabs:
    - Variable rate
    - Fixed period (fixed percent for first years, then variable margin + WIBOR)
- Form behavior:
    - Manual submit only (Calculate button)
    - Sliders only synchronize values with paired numeric inputs
    - Switching loan type tab navigates to the matching locale/rate-type URL
- Overpayment simulation modes:
    - No overpayment
    - Fixed monthly payment
    - Fixed repayment period
- For both fixed modes, user can toggle:
    - Overpay during penalty period
    - If disabled, overpayment starts after offer penalty period ends
- Cookie consent banner (EU-style accept all / necessary only)

### Results Table
- Shows offers only for selected loan type tab.
- Bank column:
    - Bank logo first line
    - Bank title below (clickable link, no raw URL text)
- Header area includes latest WIBOR snapshot date and rates.
- Sort controls: margin, monthly payment, loan period, total paid.
- Columns:
    - Rate
    - Default monthly payment
    - First month payment
    - Loan period
    - Total paid (with expanded breakdown)
- For fixed-period offers, rate column also explains fixed-years phase before variable phase.

### Payment Semantics
- Default monthly payment:
    - Includes loan installment + property insurance
    - In Fixed monthly mode, equals user selected monthly value
- First month payment:
    - Includes loan payment + life insurance + property insurance
    - In Fixed monthly mode, also includes overpayment penalty (when applicable)
    - Excludes one-time full life insurance package amount
- Total paid breakdown includes:
    - Loan amount
    - Bank interest
    - Life insurance
    - Property insurance
    - Loan fee (if present)
    - Overpayment penalty (if present)
    - Detail notes for life/property insurance calculation rules

### Custom Offer Simulation
- Public custom offer form allows manual parameter simulation.
- Keeps current main homepage simulation settings in hidden fields.
- Custom offer supports rate type selection:
    - Variable rate
    - Fixed-period rate with fixed percent and fixed years

### Admin Panel
- HTTP Basic Auth protected.
- English locale is enforced in admin namespace.
- Dashboard with quick stats and recent offer history.
- Banks management:
    - CRUD
    - Logo upload (Active Storage)
    - Description
- Loan offers management:
    - CRUD
    - Bank, optional title, offer URL, rate type, fixed-rate phase, margin, WIBOR, commission, insurance, penalty settings
    - Active flag
    - Optional history entry on update
    - Edit form no longer exposes deprecated overpayment strategy fields:
        - Overpayment starts after (years)
        - Overpayment mode
        - Overpayment coefficient
        - Overpayment fixed amount
- Loan offers list:
    - Bank column shows logos
    - Action buttons grouped in a clean layout
- WIBOR management:
    - Refresh from mBank source
    - Snapshot persistence and history

## Domain Notes
- Overpayment strategy fields still exist in schema for compatibility.
- Homepage simulation uses user-driven strategy, not per-offer default strategy fields.
- Offer penalties are still applied according to offer penalty configuration.
- Fixed-period offers use fixed percent for configured years, then recalculate installment on variable rate (margin + WIBOR) for remaining term.

## Tech Stack
- Ruby on Rails 8
- PostgreSQL
- Importmap + Turbo + Stimulus
- Active Storage
- Bootstrap
- Kamal deploy

## Setup

```bash
bundle install
bin/rails db:create db:migrate
bin/rails db:seed
bin/dev
```

App URLs:
- Public (examples):
    - http://localhost:3000/pl/oprocentowanie-zmienne
    - http://localhost:3000/en/variable-rate
    - http://localhost:3000/ua/zminna-stavka
    - http://localhost:3000/pl/oprocentowanie-stale
    - http://localhost:3000/en/fixed-period
    - http://localhost:3000/ua/fiksovana-stavka
- Site root (`/`) serves PL variable-rate comparison directly (no redirect)
- Locale root (`/pl`, `/en`, `/ua`) serves variable-rate comparison directly (no redirect)
- Polish rate-type slugs also work without locale prefix, e.g. `/oprocentowanie-zmienne`
- Full paths combine locale and slug, e.g. `/pl/oprocentowanie-stale`
- Locale switch keeps the rate-type slug when the current URL has one
- Rate-type switch always navigates to the slug path and keeps locale in the URL when present
- Sitemap: http://localhost:3000/sitemap.xml
- Robots: http://localhost:3000/robots.txt
- Admin: http://localhost:3000/admin

## Configuration

Environment variables:
- ADMIN_USERNAME (required outside development)
- ADMIN_PASSWORD (required outside development)

Development/test fallback:
- username: admin
- password: admin123

## Core Routes
- GET /(:locale)/:rate_type_slug
- GET /(:locale)
- GET /:rate_type_slug (Polish slugs, PL locale implied)
- POST /(:locale)/custom_compare
- GET /sitemap.xml
- GET /admin
- resources :banks
- resources :loan_offers
- resources :loan_offer_changes (nested under loan_offers)
- GET /admin/wibor_snapshots
- POST /admin/wibor_snapshots/refresh

### Localized rate-type slugs
| Locale | Variable | Fixed period |
|--------|----------|--------------|
| pl | `oprocentowanie-zmienne` | `oprocentowanie-stale` |
| en | `variable-rate` | `fixed-period` |
| ua | `zminna-stavka` | `fiksovana-stavka` |

Slug map source of truth: `app/models/rate_type_slug.rb`

## SEO
- Canonical + hreflang per locale for the current rate type
- Per-rate-type page titles and meta descriptions
- Sitemap lists all locale × rate-type URLs
- Admin UI is `noindex`

## Quality Checks
- Tests: bin/rails test
- Autoload check: bin/rails zeitwerk:check
- Lint/security:
    - bin/rubocop
    - bin/brakeman

## Contributor Notes
- Keep public simulation semantics aligned between:
    - Homepage form
    - LoanComparisonsController
    - LoanCalculator
    - Locale copy
- If adding sort keys, update:
    - table controls
    - row data attributes
    - Stimulus sort controller
    - locale labels
- If adding rate-type or locale URLs, update:
    - `RateTypeSlug`
    - routes constraint
    - sitemap
    - locale SEO copy

## Cloudflare tunnel settings

sudo journalctl -u cloudflared -n 50 --no-pager

cloudflared tunnel run --token-file /etc/cloudflared/token

sudo nano /etc/systemd/system/cloudflared.service

sudo systemctl daemon-reload
sudo systemctl restart cloudflared
sudo systemctl status cloudflared

cloudflared tunnel list

### Create the DNS record
sudo cloudflared tunnel route dns wcredit wcredit.pl

## Deploy

```bash
bin/deploy
```

`bin/deploy` stops the app, frees host port `3000` if a leftover container still holds it, runs `kamal deploy`, migrates inside the running web container (`app exec --reuse`), then prunes exited bloanc containers.

### WIBOR refresh

Manual:

```bash
bin/rails wibor:refresh
# production:
bin/kamal app exec --reuse "bin/rails wibor:refresh"
```

If rates are unchanged since the latest snapshot, the task only updates `fetched_at` (no new history row).

Production also runs this hourly via the Kamal `cron` role (`config/crontab`).
