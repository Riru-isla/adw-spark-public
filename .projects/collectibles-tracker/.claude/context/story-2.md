# Story 2: Collections API endpoints

## What was built
A RESTful JSON API for managing collections, nested under the `Api` namespace. The controller computes `item_count` and `total_value` aggregates directly in SQL using `left_joins` + `group` + `select`, so aggregates are always accurate without N+1 queries. Cascade deletion of items is handled by the existing `dependent: :destroy` on the model.

## Key files
- `backend/app/controllers/api/collections_controller.rb` — full CRUD controller with SQL-level aggregates and a `serialize_collection` helper that shapes all responses consistently
- `backend/config/routes.rb` — adds `namespace :api { resources :collections }` (index, show, create, update, destroy)
- `backend/spec/requests/api/collections_spec.rb` — request specs covering happy paths, validation errors, 404, cascade destroy, and aggregate values

## Database changes
- No new migrations; relies on `collections` and `items` tables from Story 1
- `items.estimated_value` (decimal) is summed for `total_value` via `COALESCE(SUM(...), 0)`

## API endpoints
- `GET /api/collections` — returns all collections with `item_count` and `total_value`
- `GET /api/collections/:id` — returns single collection with aggregates
- `POST /api/collections` — creates collection; permitted params: `name`, `category`, `description`; returns 201
- `PUT /api/collections/:id` — updates collection; returns 200 with fresh aggregates
- `DELETE /api/collections/:id` — destroys collection and its items; returns 204

## Patterns & conventions
- Aggregates computed via a single SQL query using `left_joins(:items).group(:id).select(...)` — reused in `index`, `set_collection`, and `with_aggregates` private helper
- All responses go through `serialize_collection` which casts `item_count` to int and `total_value` to float to avoid string serialization from SQL
- Validation errors returned as `{ errors: [...] }` with 422
- `before_action :set_collection` used for show/update/destroy; it also loads aggregates so `show` is consistent with `index`

## Dependencies
- No new gems or packages added

## Notes
- `with_aggregates` does a second DB query after create/update to fetch fresh aggregate values — acceptable for now but could be optimized if needed
- Items API (Story 3 likely) should follow the same namespace (`Api::ItemsController`) and serializer pattern
- The `category` field is a free-text string on `collections` — no enum enforcement at the API layer