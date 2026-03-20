# Story 5: Dashboard summary API endpoint

## What was built
A `GET /api/dashboard` endpoint that aggregates all data needed to power the frontend dashboard. It returns spending by category for the current month, a 6-month expense trend, overall budget health, and a pet mood indicator derived from budget utilization.

## Key files
- `backend/app/controllers/api/dashboard_controller.rb` — single `show` action with four private aggregation methods: `category_breakdown`, `monthly_trend`, `budget_health`, `pet_mood`
- `backend/config/routes.rb` — adds `get 'dashboard', to: 'dashboard#show'` under the `api` namespace
- `backend/spec/requests/api/dashboard_spec.rb` — request specs covering empty data, income exclusion, month filtering, 6-month trend labels, budget percentage rounding, and all three mood thresholds

## Database changes
- No new migrations in this story — relies on tables from stories 1–4 (`categories`, `transactions`, `budgets`)

## API endpoints
- `GET /api/dashboard` — returns `{ category_breakdown, monthly_trend, budget_health, pet_mood }`

## Patterns & conventions
- All aggregation logic is private methods on the controller (no separate service objects or serializers)
- Raw SQL fragments use `Arel.sql` (not string interpolation) for safety
- Month/year filtering done via Ruby `Date.current.beginning_of_month` / `end_of_month` range
- `monthly_trend` fills zero-value entries for months with no transactions so the frontend always receives exactly 6 data points

## Dependencies
- No new gems or packages added

## Notes
- `pet_mood` thresholds: `happy` = under 80% spent, `worried` = 80–100%, `sad` = over 100%
- `budget_health.percentage` can be `nil` if no budgets exist for the current month (frontend must handle this)
- `category_breakdown` only includes expense transactions — income is excluded by filtering on `transaction_type = 'expense'`
- `monthly_trend` uses `EXTRACT(YEAR FROM date)` / `EXTRACT(MONTH FROM date)` via Arel — works on PostgreSQL; not SQLite-compatible