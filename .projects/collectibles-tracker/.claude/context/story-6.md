# Story 6: Collections list and management UI

## What was built
A full collections management UI with a grid-based index page showing all collections as cards, and a modal form for creating and editing collections. Delete is handled inline on each card with a confirmation prompt. Validation errors surface inline within the modal on 422 responses.

## Key files
- `frontend/src/views/CollectionsView.vue` — Collections index page; renders cards grid, manages modal open/close state, handles delete with `window.confirm`
- `frontend/src/components/CollectionModal.vue` — Reusable create/edit modal; accepts `collection` prop (null = create mode), emits `close` and `saved`
- `frontend/src/stores/collections.ts` — Pinia store with `collections`, `loading`, `error` state; actions: `fetchCollections`, `createCollection`, `updateCollection`, `deleteCollection`; returns validation error arrays on 422
- `frontend/src/services/api.ts` — Added `getCollections`, `createCollection`, `updateCollection`, `deleteCollection`; create/update return raw `Response` for 422 inspection
- `frontend/src/router/index.ts` — Added `/collections` route (lazy-loaded `CollectionsView`)
- `frontend/src/views/__tests__/CollectionsView.spec.ts` — Tests: card rendering, loading/error states, modal open, delete confirmation
- `frontend/src/components/__tests__/CollectionModal.spec.ts` — Tests: create/edit mode rendering, cancel emit, createCollection call, inline validation errors

## Database changes
None — consumes existing API from Story 2.

## API endpoints
- `GET /api/collections` — fetch all collections (called on mount and after mutations)
- `POST /api/collections` — create; body wrapped as `{ collection: data }`
- `PATCH /api/collections/:id` — update; body wrapped as `{ collection: data }`
- `DELETE /api/collections/:id` — delete by id

## Patterns & conventions
- Store actions return `string[] | null` for validation errors (from 422 body), throw for other failures
- API service: create/update return raw `Response`; read/delete throw on non-ok
- Modal is controlled via `show` boolean prop + `close`/`saved` emits (no router navigation)
- Pinia store uses composition API style (`defineStore` with function syntax)
- Cards grid uses CSS `repeat(auto-fill, minmax(220px, 1fr))` responsive pattern
- Catppuccin dark theme colors throughout

## Dependencies
No new packages added.

## Notes
- `CollectionModal` watches both `show` and `collection` props to reset/pre-populate the form — next stories adding other modals should follow the same pattern
- `total_value` on the `Collection` interface is a number; the view formats it as currency
- The store auto-refetches after create/update/delete — no manual cache invalidation needed
- Route is lazy-loaded; ensure the dashboard nav link points to `/collections` (name: `'collections'`)