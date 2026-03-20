# Story 11: Value summary breakdowns

## What was built
Added per-collection and overall value breakdowns grouped by item condition. A reusable `ValueBreakdown` component displays condition-grouped USD totals on both the collection detail page and dashboard. Backend aggregation is handled via SQL `group(:condition).sum(:estimated_value)` in both controllers.

## Key files
- `backend/app/controllers/api/collections_controller.rb` — added `build_value_by_condition()` helper; merges `value_by_condition` hash into the `show` response only (not index)
- `backend/app/controllers/api/dashboard_controller.rb` — added `build_value_by_condition(Item.all)` to aggregate across all items; added `value_by_condition` to dashboard response
- `frontend/src/components/ValueBreakdown.vue` — reusable component; accepts `breakdown: Record<string, number>` prop; enforces canonical condition order (Mint → Near Mint → Good → Fair → Poor); filters zero-value rows; formats USD via `Intl.NumberFormat`; shows "No values recorded" when empty
- `frontend/src/components/__tests__/ValueBreakdown.spec.ts` — Vitest tests covering rendering, zero-filtering, empty state, and ordering
- `frontend/src/stores/collections.ts` — added optional `value_by_condition?: Record<string, number> | null` to `Collection` interface
- `frontend/src/stores/dashboard.ts` — added `valueByCondition` ref; populated from `data.value_by_condition ?? {}` in `fetchDashboard()`
- `frontend/src/views/CollectionDetailView.vue` — renders `<ValueBreakdown>` section between header and items grid, guarded by `v-if`
- `frontend/src/views/DashboardView.vue` — renders `<ValueBreakdown>` below stat cards, above recently added items

## Database changes
- No migrations. Uses existing `condition` enum and `estimated_value` decimal on `items` table.

## API endpoints
- `GET /api/collections/:id` — response now includes `value_by_condition: { mint: float, near_mint: float, good: float, fair: float, poor: float }`
- `GET /api/dashboard` — response now includes `value_by_condition` with same shape, aggregated across all items

## Patterns & conventions
- Backend aggregation: `items_scope.group(:condition).sum(:estimated_value)`, iterated over `Item.conditions` enum keys to ensure all conditions present (missing ones filled with `0.0`)
- `value_by_condition` is only included in collection `show`, not `index` (avoids N+1 per row)
- Frontend uses `CONDITION_ORDER` constant array to enforce display order regardless of hash key order
- Currency formatted with native `Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })` — no new library

## Dependencies
- None added

## Notes
- `value_by_condition` on `Collection` is typed as optional/nullable — only present after `fetchCollection()`, not in list responses; subsequent stories should not assume it's populated from the collections index
- The `ValueBreakdown` component is fully generic and reusable for any condition-keyed breakdown needed in future stories