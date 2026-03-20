# Story 8: Item create and edit forms with photo upload

## What was built
A reusable `ItemModal` Vue component that handles both creating and editing collectible items, including multi-photo upload with live thumbnail previews. The modal is integrated into `CollectionDetailView` (Add Item button) and `ItemDetailView` (Edit button), sharing a single component for both flows.

## Key files
- `frontend/src/components/ItemModal.vue` — modal dialog for create/edit with all item fields, photo upload with blob URL previews, existing photo removal, and FormData submission
- `frontend/src/components/__tests__/ItemModal.spec.ts` — unit tests covering create mode defaults, edit mode pre-population, condition options, file preview, photo removal, FormData contents, and 422 error display
- `frontend/src/stores/items.ts` — added `Photo` and `Item` TypeScript interfaces; added `createItem`, `updateItem`, `deleteItem` store actions that accept `FormData` and return validation errors on 422
- `frontend/src/services/api.ts` — added `createItem` and `updateItem` API functions using raw `fetch` (not `apiFetch`) to send `FormData` without a `Content-Type` header override
- `frontend/src/views/CollectionDetailView.vue` — wired up `ItemModal` with an "Add Item" button; refreshes item list on `saved` event
- `frontend/src/views/ItemDetailView.vue` — wired up `ItemModal` for edit flow; re-fetches current item on `saved` event

## Database changes
None — no new migrations. This story is purely frontend.

## API endpoints
None new. Uses existing endpoints from Story 3:
- `POST /api/collections/:id/items` — multipart FormData with `item[photos][]`
- `PATCH /api/items/:id` — multipart FormData with `item[remove_photo_ids][]`

## Patterns & conventions
- Modal is controlled externally via `show` prop and emits `close` / `saved`
- Dual-mode: `item` prop present → edit mode (pre-populates fields, shows existing photos); absent → create mode
- Photo removal tracked client-side as `removedPhotoIds[]`; sent to API as `item[remove_photo_ids][]`
- Blob URLs created via `URL.createObjectURL` for new photo previews; revoked on remove and on form reset to avoid memory leaks
- `FormData` submission bypasses `apiFetch` wrapper (which sets `Content-Type: application/json`) — raw `fetch` used so the browser sets the correct multipart boundary
- Store actions return `string[] | null`: array of error messages on 422, `null` on success

## Dependencies
No new packages added.

## Notes
- `existingPhotos` is a local copy of `item.photos` — removing a photo from the UI does not mutate the store until the form is saved
- After save, the parent view re-fetches from the server rather than relying on the optimistic store update — ensures photo URLs (ActiveStorage signed URLs) are fresh
- The condition dropdown values (`mint`, `near_mint`, `good`, `fair`, `poor`) must match the Rails enum defined in Story 3