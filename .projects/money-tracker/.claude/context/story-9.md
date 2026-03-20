# Story 9: Dashboard with charts

## What was built
A main dashboard page showing three visualizations: a spending breakdown pie chart by category, per-category budget progress bars, and a 6-month spending trend line chart. The dashboard fetches data from a dedicated Rails API endpoint and renders it using Chart.js via the `vue-chartjs` wrapper.

## Key files
- `frontend/src/views/DashboardView.vue` — main dashboard layout; fetches data on mount, renders pie chart, budget status bars, and trend chart in a responsive 2-column grid
- `frontend/src/components/SpendingPieChart.vue` — `vue-chartjs` Pie chart showing current-month spending by category with category colors
- `frontend/src/components/MonthlyTrendChart.vue` — `vue-chartjs` Line chart showing 6-month spending trend with filled area and dollar-formatted Y-axis
- `frontend/src/stores/dashboard.ts` — Pinia store; calls `GET /api/dashboard`, holds `category_breakdown` and `monthly_trend`
- `backend/app/controllers/api/dashboard_controller.rb` — single `show` action returning `category_breakdown`, `monthly_trend`, `budget_health`, and `pet_mood`
- `backend/spec/requests/api/dashboard_spec.rb` — 18 request specs covering all response keys, edge cases, and pet mood thresholds
- `frontend/src/views/__tests__/DashboardView.spec.ts` — 6 component tests with Chart.js mocked

## Database changes
None — queries existing `transactions`, `budgets`, and `categories` tables via SQL aggregations (`GROUP BY`, `EXTRACT(YEAR/MONTH FROM date)`).

## API endpoints
- `GET /api/dashboard` — returns `category_breakdown` (category/color/spent), `monthly_trend` (6-month label/total array with zero-fill), `budget_health` (totals + percentage), and `pet_mood` ("happy"/"worried"/"sad")

## Patterns & conventions
- Budget progress bar color thresholds: green <70%, yellow 70–89%, red ≥90%
- Pet mood thresholds: happy <80%, worried 80–100%, sad >100%
- Monthly trend zero-fills months with no transactions (always returns exactly 6 entries)
- Chart.js plugins are explicitly registered per component (ArcElement, LineElement, CategoryScale, etc.)

## Dependencies
- `chart.js ^4.5.1` (frontend)
- `vue-chartjs ^5.3.3` (frontend)

## Notes
- Dashboard is the root route (`/`) and is lazy-loaded
- `category_breakdown` excludes income-type transactions — filters by `transaction_type = 'expense'`
- Budget progress bars pull from the `budgets` Pinia store (`fetchBudgets(month, year)`), separate from the dashboard store
- `pet_mood` is returned by the API but not yet displayed in the UI (present in response, not rendered)