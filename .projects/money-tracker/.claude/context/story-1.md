# Story 1: Database schema and models for core entities

## What was built
Created the full database schema and ActiveRecord models for the three core entities: categories, transactions, and budgets. Established all associations, validations, and seeded 8 default categories with emoji icons and hex color codes.

## Key files
- `backend/db/migrate/20260315213049_create_categories.rb` — creates categories table (name, icon, color)
- `backend/db/migrate/20260315213122_create_transactions.rb` — creates transactions table with category FK, date index; amount as decimal(10,2)
- `backend/db/migrate/20260315213137_create_budgets.rb` — creates budgets table with unique index on `[category_id, month, year]`
- `backend/app/models/category.rb` — Category model with `has_many :transactions` and `has_many :budgets`, uniqueness on name
- `backend/app/models/transaction.rb` — Transaction model with `enum` for transaction_type and expense_kind
- `backend/app/models/budget.rb` — Budget model with month range validation (1..12) and uniqueness on category+month+year
- `backend/db/seeds.rb` — seeds 8 default categories using `find_or_create_by!` (idempotent)

## Database changes
- `categories` — `name:string`, `icon:string`, `color:string` (all non-null)
- `transactions` — `amount:decimal(10,2)`, `date:date`, `notes:text`, `category_id:bigint FK`, `transaction_type:string`, `expense_kind:string`; index on `date`
- `budgets` — `category_id:bigint FK`, `month:integer`, `year:integer`, `limit_amount:decimal(10,2)`; unique index on `[category_id, month, year]`

## API endpoints
None — this story is data layer only.

## Patterns & conventions
- `transaction_type` and `expense_kind` use Rails `enum` with string values (not integers): `{ income: "income", expense: "expense" }` and `{ fixed: "fixed", variable: "variable" }`
- `expense_kind` is nullable (not required) — only relevant for expense transactions
- Monetary amounts stored as `decimal(10,2)`, not float
- Seeds use `find_or_create_by!` for idempotency
- Categories use emoji strings for icons, hex strings for colors

## Dependencies
No new gems added beyond what was bootstrapped.

## Notes
- `transaction_type` is a reserved word in some contexts — subsequent stories using `Transaction` should use the enum accessors (`.income?`, `.expense?`) rather than querying the string column directly
- `expense_kind` is nil for income transactions; validation does not enforce presence on expense records either, so API layer should handle that if needed
- All category deletions cascade to transactions and budgets (`dependent: :destroy`)