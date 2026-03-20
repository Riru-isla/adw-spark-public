# Story 10: Pet mascot widget

## What was built
An animated pet mascot character rendered on the dashboard that reflects the user's overall budget health. The mascot has three mood states (happy, worried, sad) driven by a backend-calculated percentage of total spending vs. total budgets for the current month. Mood transitions use CSS keyframe animations.

## Key files
- `frontend/src/components/PetMascot.vue` — self-contained mascot component; accepts `mood: 'happy' | 'worried' | 'sad'` prop; renders a circular SVG-style face with CSS keyframe animations per mood
- `frontend/src/views/DashboardView.vue` — imports `PetMascot`, reads `dashboardStore.data?.pet_mood` (defaults `'happy'`), renders mascot in a `.mascot-row` section above dashboard cards
- `frontend/src/api/index.ts` — `DashboardData` interface extended with `pet_mood: 'happy' | 'worried' | 'sad'`
- `frontend/src/stores/dashboard.ts` — Pinia store; fetches `/api/dashboard` on mount, exposes `data`, `loading`, `error`
- `backend/app/controllers/api/dashboard_controller.rb` — `show` action now includes `pet_mood` key; private method computes it from current-month budget totals
- `backend/spec/requests/api/dashboard_spec.rb` — request specs covering all mood thresholds including the no-budgets edge case

## Database changes
- None — mood is computed at request time, not stored

## API endpoints
- `GET /api/dashboard` — extended to return `pet_mood: 'happy' | 'worried' | 'sad'` alongside existing `category_breakdown`, `monthly_trend`, `budget_health`

## Patterns & conventions
- Mood logic lives entirely in the backend (`dashboard_controller.rb` private method), not in the frontend store or component
- Thresholds: `< 80%` → happy, `80–100%` → worried, `> 100%` → sad; `total_budgeted == 0` also → happy
- CSS animations are scoped inside `PetMascot.vue` using `@keyframes` — bounce (happy, 1.8s), wobble (worried, 1.4s), droop (sad, 2.2s)
- Mood caption strings live in the component: "All good!", "Watch out!", "Over budget!"

## Dependencies
- None added — pure Vue + CSS, no new gems or npm packages

## Notes
- `pet_mood` is derived from the same month-scoped budget aggregation already used for `budget_health` in the dashboard response; if budget scope logic changes, mood changes with it
- The `DashboardData` TypeScript interface is the single source of truth for the shape of `/api/dashboard` — keep it in sync if the backend response evolves