# Story 12: Integration test and final polish

## What was built
Added backend request specs covering two critical integration flows (create collection → add item with photo → verify on dashboard; search by name with multiple items) and a frontend component spec for `SearchView`. Also applied polish to the dashboard: wired `collection_name` and `value_by_condition` into the API response, fixed photo URL rendering, and surfaced the `ValueBreakdown` chart on the dashboard page.

## Key files
- `backend/spec/requests/api/integration_spec.rb` — new request spec; two describe blocks testing the full create-and-verify dashboard flow and the search-by-name flow against a real DB
- `frontend/src/views/__tests__/SearchView.spec.ts` — new Vitest spec; stubs `SearchFilterPanel`, mounts `SearchView` with a real Pinia instance, asserts both result names render and that `searchItems` is called with the typed query
- `backend/app/controllers/api/dashboard_controller.rb` — added `collection_name` to `serialize_item`, added `value_by_condition` field via new `build_value_by_condition` private method, added `includes` for collection association
- `frontend/src/stores/dashboard.ts` — added `RecentItemPhoto` interface, refined `photos` type from `string[]` to `RecentItemPhoto[]`, added `valueByCondition` ref and mapping from API response
- `frontend/src/views/DashboardView.vue` — imported and rendered `ValueBreakdown` component, fixed photo src from `item.photos[0]` → `item.photos[0].url`, added `.value-by-condition` section with scoped styles

## Database changes
None — no new migrations.

## API endpoints
- `GET /api/dashboard` — now includes `value_by_condition` (condition → sum of estimated value) and `collection_name` on each item in `recently_added_items`; photos in `recently_added_items` are now objects with `{ id, url, filename, content_type }` rather than plain strings

## Patterns & conventions
- Request specs use `FactoryBot` (`create(:collection)`, `create(:item, ...)`) — factories already existed from prior stories
- `Rack::Test::UploadedFile` used to attach a real fixture PNG for the photo upload integration test; fixture lives at `backend/spec/fixtures/files/test_image.png`
- Frontend view specs stub child components by name (`SearchFilterPanel`) and emit events directly on the stub to trigger store calls
- Grid/list toggle is fully covered by the existing `CollectionDetailView.spec.ts` — no new tests added there

## Dependencies
None new.

## Notes
- `dashboard_controller#serialize_item` now calls `item.collection.name`, so the `includes(... :collection)` eager-load is required to avoid N+1 in production
- The `RecentItemPhoto` interface is exported from `dashboard.ts` — other components that render dashboard items should import it from there rather than redefining it
- All acceptance criteria are covered via request specs + Vitest component specs; no Cypress/Playwright was added