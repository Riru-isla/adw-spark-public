# Story 7: Items list and detail views

## What was built
Two Vue pages for browsing items within a collection: a collection detail page showing items in a card grid, and an item detail page showing full metadata and photos. A dedicated Pinia store manages items state separately from the existing collections store.

## Key files
- `frontend/src/views/CollectionDetailView.vue` — grid of item cards (thumbnail, name, condition, value) with loading/error/empty states; cards link to item detail
- `frontend/src/views/ItemDetailView.vue` — full item detail with photo gallery, metadata (condition, value, acquisition date, notes), back navigation to collection
- `frontend/src/stores/items.ts` — Pinia store with `Item` and `Photo` TypeScript interfaces; actions `fetchItems(collectionId)` and `fetchItem(itemId)`
- `frontend/src/services/api.ts` — added `getItems(collectionId)` and `getItem(itemId)` API functions
- `frontend/src/router/index.ts` — added two lazy-loaded routes: `/collections/:id` and `/collections/:id/items/:itemId`
- `frontend/src/views/__tests__/CollectionDetailView.spec.ts` — 5 Vitest tests covering fetch, card rendering, empty state, loading state, and router links
- `frontend/src/views/__tests__/ItemDetailView.spec.ts` — 5 Vitest tests covering fetch, metadata rendering, photo rendering, no-photo placeholder, and back link

## Database changes
None — reads existing items/photos data via existing API.

## API endpoints
None new — consumes existing endpoints from Story 3:
- `GET /api/collections/:id/items` — via `getItems(collectionId)`
- `GET /api/items/:id` — via `getItem(itemId)`

## Patterns & conventions
- Items store follows the same pattern as the collections store (Pinia, TypeScript interfaces, loading/error state)
- Views use `onMounted` to trigger store fetches via `useRoute().params`
- Route params: collection uses `:id`, item uses `:itemId` (both present on item detail route)
- Currency formatted with `Intl.NumberFormat` for USD; condition displayed via a label-mapping helper
- Photos accessed via URL from the `Photo` interface (matches Rails attachment URL from Story 3)

## Dependencies
No new packages added.

## Notes
- The `CollectionDetailView` fetches items but does NOT fetch the collection name independently — it may need the collections store or a dedicated endpoint if the header needs to show the collection name; check how the collection name is sourced
- Item detail back-link uses `/collections/:id` derived from the route params, so both `:id` and `:itemId` must be present in the URL for back navigation to work correctly
- Photo URLs are expected to come directly from the API response; no local URL construction