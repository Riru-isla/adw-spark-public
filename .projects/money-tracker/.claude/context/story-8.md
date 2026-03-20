# Story 8: Budget management UI with progress bars

## What was built
A full-stack budget management feature allowing users to set monthly spending limits per category and track progress visually. The backend exposes two API endpoints that compute real-time spending from existing transactions. The frontend provides a dedicated Budgets page with color-coded progress bars and a modal form for setting/updating limits.

## Key files
- `backend/app/models/budget.rb` — Budget model with validations (month 1–12, positive limit, composite uniqueness on category+month+year)
- `backend/app/controllers/api/budgets_controller.rb` — `index` (with computed spent/remaining) and `create` (upsert via `find_or_initialize_by`)
- `backend/db/migrate/20260315213137_create_budgets.rb` — Creates `budgets` table with unique index on `[category_id, month, year]`
- `frontend/src/views/BudgetsView.vue` — Main page: month navigation, budget cards, progress bars, Set Budget modal, totals footer
- `frontend/src/stores/budgets.ts` — Pinia store with `budgets`, `loading`, `error`, `month`, `year` state; `totalLimit`/`totalSpent` computed; `fetchBudgets`, `saveBudget`, `setMonth` actions
- `frontend/src/api/index.ts` — Added `Budget` interface, `getBudgets(month, year)`, `upsertBudget(data)` API functions
- `frontend/src/router/index.ts` — Added `/budgets` route
- `backend/spec/requests/api/budgets_spec.rb` — Request specs covering index filters, spending calculations, upsert, and validation errors
- `backend/spec/models/budget_spec.rb` — Model validations and uniqueness tests
- `backend/spec/factories/budgets.rb` — Budget factory
- `frontend/src/stores/budgets.spec.ts` — Store unit tests with mocked API
- `frontend/src/views/BudgetsView.spec.ts` — Component tests for progress bar widths, color thresholds, navigation, and modal

## Database changes
- New `budgets` table: `category_id` (FK), `month` (integer 1–12), `year` (integer), `limit_amount` (decimal 10,2), timestamps
- Unique composite index on `[category_id, month, year]`

## API endpoints
- `GET /api/budgets?month=3&year=2026` — returns budgets for given month/year (defaults to current) with computed `spent_amount` and `remaining_amount` per budget, including nested `category`
- `POST /api/budgets` — upsert budget for a category/month/year; returns 201 with computed fields, 422 on validation failure

## Patterns & conventions
- **Upsert via `find_or_initialize_by`** — POST handles both create and update; no separate PUT/PATCH endpoint
- **Computed spending at request time** — `spent_amount` is summed from transactions on read; not stored in the DB
- **Transaction type filter** — Only `"expense"` transactions count toward spending; income is excluded
- **Threshold-based progress bar colors** — `<70%` green (uses category color), `70–90%` yellow, `>90%` red; width capped at 100% even when over budget
- **Month navigation with year rollover** — prev/next buttons handle Dec→Jan and Jan→Dec year boundary

## Dependencies
No new gems or packages added.

## Notes
- `spent_amount` is computed on every `GET /api/budgets` request by joining transactions — no caching; acceptable for current scale
- The unique DB index + model-level uniqueness validation both enforce one budget per category/month/year
- `App.vue` was updated to add a nav link to `/budgets`
- Story 9 (if it involves expense entry or categories) can rely on `category.color` already being used for progress bar theming