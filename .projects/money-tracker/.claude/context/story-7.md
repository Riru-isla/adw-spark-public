# Story 7: Transaction logging and list UI

## What was built
A full transactions page with a form to add new transactions and a filterable list. The backend exposes a `/api/transactions` REST API (index, create, destroy) backed by a new `transactions` table. The frontend provides a Pinia store, a `TransactionForm` component, and a `TransactionsView` page with live filtering.

## Key files
- `backend/app/models/transaction.rb` — Transaction model with `transaction_type` (income/expense) and `expense_kind` (fixed/variable) string enums, belongs_to category
- `backend/app/controllers/api/transactions_controller.rb` — index (with filters), create (201/422), destroy (204/404)
- `backend/db/migrate/20260315213122_create_transactions.rb` — creates `transactions` table; index on `date`
- `backend/config/routes.rb` — `resources :transactions, only: [:index, :create, :destroy]` under `/api` namespace
- `frontend/src/stores/transactions.ts` — Pinia store: state (transactions, loading, error, filters), actions (fetchTransactions, addTransaction, removeTransaction, setFilters)
- `frontend/src/components/TransactionForm.vue` — form with amount, date, type, expense_kind (conditional on expense), category, notes; client-side validation; emits `saved`
- `frontend/src/views/TransactionsView.vue` — filter bar (category, type, kind, date range), transaction list with color-coded category bar and amount, delete with confirm dialog
- `frontend/src/api/index.ts` — `getTransactions(filters?)`, `createTransaction(data)`, `deleteTransaction(id)`
- `frontend/src/router/index.ts` — `/transactions` route → `TransactionsView` (lazy loaded)

## Database changes
- New table `transactions`: `amount` (decimal 10,2 not null), `date` (date not null), `notes` (text nullable), `category_id` (FK not null), `transaction_type` (string not null), `expense_kind` (string nullable), timestamps
- Index on `date` column
- `categories` model updated with `has_many :transactions, dependent: :destroy`

## API endpoints
- `GET /api/transactions` — returns all transactions ordered by date desc; accepts query params `category_id`, `transaction_type`, `expense_kind`, `start_date`, `end_date`; eager-loads category
- `POST /api/transactions` — creates transaction; 201 on success, 422 with errors on failure, handles invalid enum ArgumentError
- `DELETE /api/transactions/:id` — 204 on success, 404 if not found

## Patterns & conventions
- Enums stored as strings (`{ income: "income" }`) — avoids integer-to-string confusion in JSON
- Controller filters chained via scoping (each optional param narrows the relation)
- Pinia store calls `fetchTransactions()` after `setFilters()` automatically
- `expense_kind` field conditionally shown/required only when `transaction_type === "expense"`
- Currency formatted as USD via `Intl.NumberFormat`

## Dependencies
- No new gems or npm packages added (Pinia and Vue Router were already present from prior stories)

## Notes
- Filtering is server-side; the store re-fetches on every filter change — no client-side filtering
- `addTransaction` prepends the new record locally (no full re-fetch) to keep the list fast
- Notes are truncated to 40 chars in the list view; full text is not expanded inline
- Delete uses a `window.confirm` dialog — a proper modal may be expected in later stories
- The `expense_kind` column is nullable at the DB level; income transactions leave it null