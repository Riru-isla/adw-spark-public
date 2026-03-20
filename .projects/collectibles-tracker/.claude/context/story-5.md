# Story 5: Vue app shell and dashboard page

## What was built
Set up the Vue 3 frontend application shell with a sidebar navigation layout and two routes (Dashboard and Collections). The dashboard page fetches data from the Story 4 API endpoint and displays aggregate stats plus recently added item cards with thumbnails.

## Key files
- `frontend/src/App.vue` — Root layout: dark sidebar nav with `RouterLink` active highlighting, `RouterView` main content area
- `frontend/src/router/index.ts` — Two routes: `/` → `DashboardView` (eager), `/collections` → `CollectionsView` (lazy-loaded)
- `frontend/src/views/DashboardView.vue` — Dashboard page: stat cards (collections, items, value), recently added item cards with photo thumbnails, loading/error states
- `frontend/src/views/CollectionsView.vue` — Stub only (`<h1>Collections</h1>`); not yet implemented
- `frontend/src/stores/dashboard.ts` — Pinia store; holds dashboard stats + `recentlyAddedItems`, `fetchDashboard()` async action
- `frontend/src/services/api.ts` — Base `apiFetch()` wrapper (prefixes `/api`, sets JSON headers) + `getDashboard()` calling `GET /api/dashboard`
- `frontend/vite.config.ts` — Added dev-server proxy: `/api` → `http://localhost:3000`
- `frontend/src/views/__tests__/DashboardView.spec.ts` — Vitest unit tests covering stat rendering, item cards, loading state, mount lifecycle

## Database changes
None.

## API endpoints
- `GET /api/dashboard` — consumed (not defined here; defined in Story 4)

## Patterns & conventions
- Pinia stores use the composition API style (`defineStore` with `ref` + returned object)
- All API calls go through `apiFetch()` in `src/services/api.ts` which prefixes `/api`
- `@` alias maps to `src/` (configured in vite.config.ts)
- Active nav link uses `exact-active-class="active"` for `/` and `active-class="active"` for `/collections`
- Styling is co-located in single-file components (scoped); global resets live in `App.vue` (unscoped)
- Currency formatted via `Intl.NumberFormat` (en-US, USD)

## Dependencies
- `pinia` ^3.0.4 — state management
- `vue-router` ^5.0.3 — client-side routing
- `@vue/test-utils` ^2.4.6 — component testing
- `vitest` ^4.0.18 — test runner
- `vite-plugin-vue-devtools` ^8.0.6 — dev tooling

## Notes
- `CollectionsView.vue` is a stub — Story 6+ will implement it; the route already exists so navigation works
- `RecentItem` interface in the store expects `photos: string[]` (array of URLs); the dashboard renders `item.photos[0]` as the thumbnail src
- Vite proxy is dev-only; production will need the Rails server to serve the built frontend or a reverse proxy
- Default `src/assets/main.css` was trimmed to just `@import './base.css'`; base.css still has the original Vue scaffold CSS vars (unused by this app's styling)
- Old scaffold files (`HelloWorld.vue`, `TheWelcome.vue`, counter store, `HomeView`, `AboutView`) were deleted