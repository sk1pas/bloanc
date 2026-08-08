# bloanc

Mortgage offer comparison app for Polish real estate loans (PLN), built with Rails conventions and minimal external dependencies.

## Product Goal
- Compare bank mortgage offers with realistic costs, not just base installment.
- Include commissions, life/property insurance, and overpayment rules.
- Support admin-managed offers with optional change history.
- Support public multilingual UI (PL default, EN, UA).

## Implemented Scope (MVP)

### Public side
- Locale-aware homepage with calculator inputs:
    - Loan amount (number input + slider)
    - Loan period (years), default 25 years
    - Loan period control (number input + slider)
    - Sliders synchronize values with number inputs (calculation happens on button click)
- Overpayment simulation section:
    - Default mode: no overpayment
    - Mode 1: fixed monthly payment interpreted as total monthly budget (bank payment + insurance + user overpayment)
    - Mode 2: fixed repayment period (system computes required monthly payment)
    - Fully clickable option cards with inline mode-specific inputs and sliders
    - Manual submit with Calculate button placed at the end of the form
- Results table with:
    - Bank logo on the first line and centered bank title link below
    - Latest WIBOR snapshot shown in table header area
    - Offer title
    - Effective rate value (margin + selected WIBOR) with formula note
    - Default monthly payment column
    - First month payment column (includes insurance and temporary fees)
    - Loan period after simulation
    - One wide Total paid column with readable breakdown:
        - loan amount
        - bank interest
        - life insurance
        - property insurance
        - loan fee (if exists)
        - overpayment penalty (if exists)
    - Detailed life/property insurance descriptors (percent, required period, monthly/one-time behavior)
    - Calculation notes attached to relevant columns without zero-value noise
    - Expandable long notes
- Frontend sorting controls directly above the results table (no server-side pagination dependency), including sort by loan period.
- Custom offer calculator form (manual bank/offer parameters).

### Admin side (HTTP Basic Auth)
- English-only locale in admin area for consistent operations.
- Dashboard with quick metrics and recent offer history entries.
- Banks management (CRUD):
    - Logo (Active Storage attachment)
    - Title
    - Description
    - Website URL
- WIBOR management:
    - Refresh from mBank endpoint
    - Persist WIBOR 1M and 3M snapshot
    - Show latest effective date and refresh time
    - Keep historical snapshots
- Loan offers management (CRUD):
    - Bank assignment
    - Margin and WIBOR type
    - Commission
    - Insurance settings
    - Overpayment settings and penalties
    - Active flag
- Offer change history:
    - Optional history save on update
    - Note per history entry
    - Snapshot payload stored in JSONB
- Compact layout and controlled field widths (no overextended full-width forms).

## UX / Design
- Bootstrap-based UI.
- Public area: light, high-contrast palette.
- Admin area: dark-themed palette.
- Admin table rows and headers are fully dark-themed.

## Tech Stack
- Ruby on Rails 8
- PostgreSQL
- Importmap + Turbo/Stimulus
- Active Storage for bank logos

## Domain Model

### `Bank`
- `title` (required)
- `description`
- `website_url`
- `logo` attachment
- has_many `LoanOffer`

### `WiborSnapshot`
- `effective_date` (unique)
- `wibor_1m`
- `wibor_3m`
- `fetched_at`
- `source_url`
- `payload` (raw API response JSON)

### `LoanOffer`
- belongs_to `Bank`
- core fields:
    - `title`, `description`
    - promo period: `promoted_from`, `promoted_until`
    - `bank_margin_percent`
    - `wibor_kind` enum: `wibor_1m`, `wibor_3m`
    - `bank_commission_percent`
- insurance fields:
    - `life_insurance_percent`
    - `life_insurance_years`
    - `life_insurance_total` (one-time override)
    - `property_insurance_monthly`
- overpayment fields:
    - `overpayment_grace_years`
    - `overpayment_mode` enum: `no_overpayment`, `coef`, `absolute`
    - `overpayment_coef`
    - `overpayment_amount`
    - `overpayment_penalty_years`
    - `overpayment_penalty_percent`
    - `overpayment_penalty_min_amount`
- `active` flag

### `LoanOfferChange`
- belongs_to `LoanOffer`
- `changed_at`
- `note`
- `snapshot` JSONB (`previous` and `current` payload)

## Loan Calculation Rules

Implemented in `LoanCalculator`:
- Annuity monthly installment based on margin + WIBOR.
- Total cost includes:
    - principal + interest payments
    - bank commission
    - property insurance
    - life insurance
    - overpayment penalties
- Supports overpayment scenarios:
    1. Default (no overpayment).
    2. User-defined fixed monthly total budget (converted to principal overpayment after recurring insurance costs, with penalty-aware adjustment).
    3. User-defined fixed target period.
    4. Overpayment penalty with percent and minimum amount (when overpayment is active).
- Tracks repayment shortening (`months_paid`).
- Produces notes to explain result composition.

## WIBOR Refresh Strategy
- Source: mBank JSON endpoint pattern:
    - `https://www.mbank.pl/api/libor/libor_date_YYYY-MM-DD.json`
- Fetcher scans recent days (lookback window) until it finds PLN/WIBOR item.
- On same `effective_date`, existing snapshot is updated (idempotent refresh).

## Routes (Core)
- Public:
    - `GET /(:locale)` -> comparison page
    - `POST /(:locale)/custom_compare` -> custom offer simulation
- Admin:
    - `GET /admin`
    - `resources :banks`
    - `resources :loan_offers` + nested `loan_offer_changes#index`
    - `GET /admin/wibor_snapshots`
    - `POST /admin/wibor_snapshots/refresh`

## Configuration

### Environment variables
- `ADMIN_USERNAME` (required outside development)
- `ADMIN_PASSWORD` (required outside development)

Development/test fallback credentials:
- username: `admin`
- password: `admin123`

## Internationalization
- Available locales: `pl`, `en`, `ua`
- Default locale: `pl`
- Admin namespace locale is forced to English.

## Setup
```bash
bundle install
bin/rails db:create db:migrate
bin/rails db:seed
bin/dev
```

App URLs:
- public: `http://localhost:3000/pl`
- admin: `http://localhost:3000/admin`

## Suggested Seed Data Strategy
- Keep 1 current `WiborSnapshot`.
- Add 3-5 sample banks.
- Add 1-3 offers per bank with mixed overpayment configurations.

## Testing / Quality
- Run tests: `bin/rails test`
- Validate autoloading: `bin/rails zeitwerk:check`
- Lint/security (already in Gemfile):
    - `bin/rubocop`
    - `bin/brakeman`

## AI-Agent Notes (Important)
- Preserve enum values and calculator parameter names; they are used by forms and result sorting.
- Avoid introducing extra frontend frameworks unless explicitly requested.
- Keep public and admin styling in the shared stylesheet with theme classes (`public-theme`, `admin-theme`).
- Public table sorting is frontend-driven (Stimulus). If extending sort keys, update:
    - sort controls in homepage view
    - row data attributes
    - Stimulus sort controller
    - i18n labels
- Overpayment simulation defaults to no overpayment and is user-driven from homepage controls.

## Next High-Value Enhancements
1. Add request/model/unit tests for calculator, admin CRUD, and WIBOR fetcher.
2. Add pagination and filtering in admin lists.
3. Add optional CSV export for comparison results.
4. Add per-offer simulation presets and saved user scenarios.
