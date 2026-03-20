# Story 6: Vue app shell and category management UI

## What was built
Set up the Vue 3 frontend with a sidebar layout, Vue Router with four routes (Dashboard, Transactions, Categories, Budgets), and a full category CRUD UI. Categories can be created, edited, and deleted via a modal form with a hex color picker and icon selection. The other three views are placeholder stubs for future stories.

## Key files
- `frontend/src/App.vue` — app shell with fixed 220px sidebar nav and `<RouterView>` main content area
- `frontend/src/router/index.ts` — Vue Router with lazy-loaded routes for `/`, `/transactions`, `/categories`, `/budgets`
- `frontend/src/main.ts` — bootstraps Vue app, registers Pinia and Router
- `frontend/src/views/CategoriesView.vue` — category list as cards with add/edit/delete, modal dialog, loading/error/empty states
- `frontend/src/components/CategoryForm.vue` — form with name input, `<hex-color-picker>` custom element, 8 preset icon chips + free-text icon input
- `frontend/src/stores/categories.ts` — Pinia store with `fetchCategories`, `addCategory`, `editCategory`, `removeCategory` actions
- `frontend/src/api/index.ts` — API client with `Category`/`CategoryData` TypeScript interfaces, base URL from `VITE_API_URL`
- `frontend/src/views/DashboardView.vue` — placeholder `<h1>` only
- `frontend/src/views/TransactionsView.vue` — placeholder `<h1>` only
- `frontend/src/views/BudgetsView.vue` — placeholder `<h1>` only
- `frontend/src/components/__tests__/CategoriesView.spec.ts` — tests for list render, add button, delete confirmation
- `frontend/src/components/__tests__/CategoryForm.spec.ts` — tests for field render, submit emit, validation, edit pre-fill

## Database changes
None — this story is frontend only.

## API endpoints
Consumed (not added here — defined in Story 2):
- `GET /api/categories` — fetch all categories
- `POST /api/categories` — create category
- `PATCH /api/categories/:id` — update category
- `DELETE /api/categories/:id` — delete category

## Patterns & conventions
- Pinia stores in `src/stores/` with TypeScript, one file per domain
- API layer centralized in `src/api/index.ts` with typed interfaces (`Category`, `CategoryData`)
- Views in `src/views/`, reusable components in `src/components/`
- Modals are inline in the view using `v-if` + local `showForm`/`editingCategory` state
- `hex-color-picker` is a web component from `vanilla-colorful`; must stub it in Vitest via `config.global.components`
- Vite proxies `/api` → `http://localhost:3000` in dev

## Dependencies
- `vanilla-colorful ^0.7.2` — hex color picker web component
- `pinia ^3.0.4` — state management
- `@vueuse/core ^14.2.1` — Vue composition utilities
- `vue-router ^5.0.3` — routing (may have already been scaffolded; wired up here)

## Notes
- Dashboard, Transactions, and Budgets views are stubs — subsequent stories should replace their `<h1>` placeholders with real content
- The `Category` type (`{ id, name, color, icon }`) is defined in `src/api/index.ts` — import from there for consistency
- Color is stored as a hex string (e.g. `#ff5733`); icon is a free-text string with 8 suggested presets
- API base URL defaults to `http://localhost:3000` if `VITE_API_URL` is not set