# Story 2: Categories API endpoints

## What was built
RESTful CRUD API for managing spending/income categories under the `Api` namespace. Categories have a name, color, and icon, and are protected from deletion when referenced by transactions.

## Key files
- `backend/app/controllers/api/categories_controller.rb` — CRUD controller with delete protection and error handling
- `backend/app/models/category.rb` — Category model with validations (name uniqueness, presence of name/icon/color) and associations to transactions/budgets
- `backend/config/routes.rb` — Namespaced routes under `api`, resources limited to index/create/update/destroy
- `backend/db/migrate/20260315213049_create_categories.rb` — Creates `categories` table with `name`, `icon`, `color` (all non-null strings)
- `backend/spec/requests/api/categories_spec.rb` — Full request specs covering all endpoints and edge cases
- `backend/spec/models/category_spec.rb` — Model validations and association specs
- `backend/spec/factories/categories.rb` — FactoryBot factory with sequence names, default icon 🏠, color `#EF4444`

## Database changes
- New table: `categories` with columns `name string NOT NULL`, `icon string NOT NULL`, `color string NOT NULL`, plus timestamps

## API endpoints
- `GET /api/categories` — returns all categories ordered by name
- `POST /api/categories` — creates category; returns 422 with `errors` on failure
- `PATCH /api/categories/:id` — updates category; returns 404 or 422 on failure
- `DELETE /api/categories/:id` — destroys category; returns 422 if transactions exist, 204 on success

## Patterns & conventions
- Controllers namespaced under `Api` module, located in `app/controllers/api/`
- Errors returned as `{ errors: record.errors }` (validation) or `{ error: "message" }` (domain rule / not found)
- Delete protection via `category.transactions.exists?` check — not enforced at DB level
- `has_many :transactions, dependent: :destroy` and `has_many :budgets, dependent: :destroy` declared on model (but destroy is blocked before that code path is reached)

## Dependencies
No new gems added — uses existing Rails 8.1 stack, rspec-rails, factory_bot_rails, shoulda-matchers, rack-cors.

## Notes
- `Transaction` and `Budget` models already have `belongs_to :category` — those associations are in place from Story 1
- No serializer/jbuilder used — plain `render json: record` relies on default ActiveRecord `as_json`
- Budget delete protection is not yet implemented (only transactions are checked); future budget story may need to extend the destroy action