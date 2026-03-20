# Story 3: Transactions API endpoints

## What was built
RESTful API endpoints for logging income and expenses under the `/api/transactions` namespace. The implementation covers creating, listing, and deleting transactions with filtering support via query params.

## Key files
- `backend/app/controllers/api/transactions_controller.rb` — index/create/destroy actions with query param filtering
- `backend/app/models/transaction.rb` — model with enums, validations, and category association
- `backend/db/migrate/20260315213122_create_transactions.rb` — creates transactions table
- `backend/config/routes.rb` — transactions registered under `api` namespace with index, create, destroy
- `backend/spec/requests/api/transactions_spec.rb` — request specs covering all three endpoints
- `backend/spec/models/transaction_spec.rb` — model validation and enum tests
- `backend/spec/factories/transactions.rb` — FactoryBot factory with sensible defaults

## Database changes
- New `transactions` table: `amount` (decimal 10,2), `date` (indexed), `notes` (text, optional), `category_id` (FK, indexed), `transaction_type` (string, required), `expense_kind` (string, optional), timestamps

## API endpoints
- `GET /api/transactions` — returns all transactions ordered by date desc; supports `category_id`, `transaction_type`, `expense_kind`, `start_date`, `end_date` query params
- `POST /api/transactions` — creates a transaction; returns 422 with errors on validation failure
- `DELETE /api/transactions/:id` — destroys a transaction; returns 404 if not found

## Patterns & conventions
- Controller lives at `app/controllers/api/transactions_controller.rb` under the `Api` module
- No custom serializers — uses Rails `as_json` with `:include => :category` inline
- Enums defined on the model: `transaction_type` (income/expense), `expense_kind` (fixed/variable)
- Strong params via `transaction_params` private method
- `set_transaction` before_action for member routes

## Dependencies
No new gems added.

## Notes
- `expense_kind` is optional — only relevant for expense transactions; income records leave it nil
- Filtering is additive (each query param chains onto the same relation)
- `belongs_to :category` is required by default in Rails 5+; ensure category always exists when creating transactions in subsequent stories
- No pagination yet — full result set returned; consider this if the list view story needs it