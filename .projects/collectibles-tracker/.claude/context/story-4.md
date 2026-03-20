# Story 4: Dashboard API endpoint

## What was built
A single `GET /api/dashboard` endpoint that returns aggregate statistics across all collections and items. The controller queries counts, sums estimated values (treating nulls as 0), and returns the 10 most recently added items with their photo URLs.

## Key files
- `backend/app/controllers/api/dashboard_controller.rb` — `DashboardController#show` computes stats and serializes recently added items with photo attachments
- `backend/config/routes.rb` — added `get 'dashboard', to: 'dashboard#show'` inside the `api` namespace
- `backend/spec/requests/api/dashboard_spec.rb` — request specs covering empty state, aggregate counts/sum, 10-item limit with ordering, and photo URL inclusion

## Database changes
None — no new migrations; reads from existing `collections` and `items` tables.

## API endpoints
- `GET /api/dashboard` — returns `total_collections`, `total_items`, `total_estimated_value` (float, nulls summed as 0), and `recently_added_items` (last 10 items ordered by `created_at DESC`, each with full photo metadata)

## Patterns & conventions
- Controller lives in `app/controllers/api/` as `Api::DashboardController`, consistent with other API controllers
- Private `serialize_item` helper mirrors the item serialization pattern from `ItemsController` — includes `id`, `collection_id`, `name`, `condition`, `estimated_value`, `acquisition_date`, `notes`, `created_at`, and `photos` array
- Each photo in the array has `id` (blob_id), `url` (absolute via `rails_blob_url`), `filename`, and `content_type`
- Uses `includes(photos_attachments: :blob)` to avoid N+1 on photo loading
- `Item.sum(:estimated_value).to_f` handles nil values correctly (Rails `sum` returns 0 for all-nil columns)

## Dependencies
None added.

## Notes
- `rails_blob_url` requires `host: request.base_url` since this is an API-only controller without default URL options — next stories that need to generate attachment URLs should follow this same pattern
- The `recently_added_items` serialization is a subset of the full item shape (no `collection` embed) — if a frontend story needs collection name on the dashboard, the serializer will need extending