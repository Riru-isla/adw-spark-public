# Story 10: Search and filter functionality

## What was built
A full-text search and filter system spanning backend and frontend. The backend gained a `search` scope on `Item` and a dedicated `GET /api/items/search` endpoint. The frontend got a dedicated `/search` route with a `SearchFilterPanel` component that debounces input and emits combined filter params to `SearchView`.

## Key files
- `backend/app/models/item.rb` — added `scope :search` with chainable filters for query (ILIKE on name/notes), collection_id, condition, value_min, value_max
- `backend/app/controllers/api/items_controller.rb` — added `search` action; category filter applied separately via `joins(:collection)` since it lives on the collection model
- `backend/config/routes.rb` — added `get 'items/search', to: 'items#search'` at the top-level API namespace (must appear before `resources :items` to avoid routing conflict)
- `backend/spec/requests/api/items_spec.rb` — added 9 search specs covering all filter combinations, case-insensitivity, and empty results
- `frontend/src/components/SearchFilterPanel.vue` — filter UI with search text input, collection dropdown, category text input, condition dropdown, and min/max value inputs; 300ms debounce on all changes; shows active filter count badge and "Clear filters" button
- `frontend/src/views/SearchView.vue` — page view at `/search`; orchestrates `SearchFilterPanel` + results grid with thumbnail, collection name, condition, and value; links each result to its item detail page
- `frontend/src/stores/items.ts` — added `searchResults`, `searching` reactive state and `searchItems` action
- `frontend/src/services/api.ts` — added `SearchParams` interface and `searchItems()` function that builds a query string and calls `GET /api/items/search`
- `frontend/src/router/index.ts` — added `/search` route pointing to `SearchView`
- `frontend/src/App.vue` — added "Search" link to sidebar nav

## Database changes
None — no new migrations. Search uses existing columns (`name`, `notes`, `condition`, `estimated_value`, `collection_id`) with `ILIKE` and numeric comparisons.

## API endpoints
- `GET /api/items/search` — accepts `query`, `collection_id`, `category`, `condition`, `value_min`, `value_max`; returns array of serialized items (same shape as other item endpoints, including `photos` array)

## Patterns & conventions
- Category filter joins through the `collections` table (`collections.category ILIKE`) since `category` is a collection attribute, not an item attribute
- The `items/search` route is declared **before** `resources :items` in routes.rb to prevent Rails routing it as `items#show` with id `"search"`
- Search text input uses 300ms debounce; dropdown/range inputs share the same debounce watcher
- `searching` boolean (separate from `loading`) used to distinguish search-in-progress from item-load-in-progress

## Dependencies
None — no new gems or npm packages.

## Notes
- The `category` filter matches against `collections.category`, not a field on items — keep this in mind if a future story moves category to items directly
- Search fires on every change (debounced); there is no explicit "Search" submit button — the next story should be aware that results update reactively
- `SearchView` resolves collection names by looking up `collectionsStore.collections`; it calls `fetchCollections` on mount only if the store is empty