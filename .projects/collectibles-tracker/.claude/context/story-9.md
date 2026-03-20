# Story 9: Grid and list view toggle

## What was built
Added a grid/list view toggle to `CollectionDetailView`. Grid view renders items as photo cards in a responsive CSS grid; list view renders a compact table with name, condition, value, and acquisition date columns. The selected mode persists across navigations via `sessionStorage`.

## Key files
- `frontend/src/views/CollectionDetailView.vue` — modified to add `viewMode` ref, toggle buttons, grid card layout (`.item-cards`), list table (`.item-table`), and all associated scoped CSS
- `frontend/src/views/__tests__/CollectionDetailView.spec.ts` — expanded with 8 new tests covering toggle behavior, sessionStorage persistence/restore, and list view table column rendering

## Database changes
None.

## API endpoints
None.

## Patterns & conventions
- View preference stored in `sessionStorage` under key `itemViewMode` (session-scoped, not persisted across browser closes)
- `viewMode` is a `ref<'grid' | 'list'>`, initialized from `sessionStorage` with `'grid'` as default
- A `watch` on `viewMode` writes back to `sessionStorage` on every change
- Toggle buttons use `.view-btn` + `.active` class pattern (no icon library — text labels "Grid" / "List")
- List table rows use `RouterLink` with `custom` + `v-slot="{ navigate }"` to make `<tr>` elements navigable

## Dependencies
None added.

## Notes
- The grid view was already present from Story 7 (`.item-cards` markup); this story extracted it into a conditional and added the list view alongside it
- `sessionStorage` key is global (not scoped per collection), so switching view in one collection persists to all others — intentional per the story requirement ("persists during the session")
- List view table columns: Name, Condition, Value, Acquired — matches Story 7's item data shape exactly