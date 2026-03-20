# Story 4: Monthly budgets API endpoints

## What was built
REST API endpoints for managing monthly category budgets. A `Budget` model stores per-category spending limits scoped to a specific month/year, and the controller computes `spent_amount` and `remaining_amount` dynamically from existing transactions on each request.

## Key files
- `backend/db/migrate/20260315213137_create_budgets.rb` — creates `budgets` table with `category_id`, `month`, `year`, `limit_amount`; unique index on `[category_id, month, year]`
- `backend/app/models/budget.rb` — `belongs_to :category`; validates month (1–12), year (positive integer), limit_amount (positive), uniqueness scoped to category+year
- `backend/app/controllers/api/budgets_controller.rb` — `index` and `create` actions; spending calculated inline from expense transactions
- `backend/config/routes.rb` — `resources :budgets, only: [:index, :create]` under `api` namespace
- `backend/spec/models/budget_spec.rb` — unit tests for validations and associations
- `backend/spec/requests/api/budgets_spec.rb` — integration tests for both endpoints
- `backend/spec/factories/budgets.rb` — FactoryBot factory (default month: 1, year: 2026, limit: 500.00)

## Database changes
- New table: `budgets` — `category_id` (FK), `month` integer (1–12), `year` integer, `limit_amount` decimal(10,2)
- Unique index on `[category_id, month, year]`

## API endpoints
- `GET /api/budgets?month=M&year=Y` — returns all budgets for the given month/year (defaults to current); each record includes category details, `limit_amount`, `spent_amount`, `remaining_amount`
- `POST /api/budgets` — creates or updates a budget (upsert via `find_or_initialize_by`); returns 201 with computed amounts, 422 on validation failure

## Patterns & conventions
- Spending is computed on-the-fly in the controller by summing expense-type transactions for the budget's category within the month/year — no stored `spent_amount` column
- Upsert pattern uses `find_or_initialize_by(category_id:, month:, year:)` then `assign_attributes` + `save`
- Income transactions are excluded from spending calculation (filters by `transaction_type: "expense"`)
- Month/year default to `Date.current.month` / `Date.current.year` when params are absent

## Dependencies
No new gems or packages added.

## Notes
- `remaining_amount` can go negative if spending exceeds the limit — no clamping at zero
- The unique DB index enforces budget-per-category-per-month integrity at the database level, complementing the model validation
- Subsequent stories that display budget vs. actual data can rely on the `spent_amount` / `remaining_amount` fields already being present in the GET response