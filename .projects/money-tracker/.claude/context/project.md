# Penny Pals — Project Context

## Overview

Penny Pals is a personal money tracker app where users log income and expenses, organize transactions by category, set monthly spending budgets, and view colorful dashboard charts. The UI has a friendly, playful feel with a pet mascot character whose mood reflects overall budget health.

## Architecture

- **Backend:** Rails 8.1 API-only (under `/api` namespace), PostgreSQL 16
- **Frontend:** Vue 3 + TypeScript, Vite, Pinia, Vue Router 5
- **Charts:** Chart.js 4 via vue-chartjs 5
- **Color picker:** vanilla-colorful web component
- **No authentication** — single-user app
- **CORS** enabled via rack-cors; Vite dev server proxies `/api` calls to `localhost:3000`
- **Spending calculated on-the-fly** at request time (no caching or materialized views)
- **Income excluded** from all spending calculations, budget health, and charts

## Database Schema

### `categories`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| name | string | unique, not null |
| icon | string | emoji or string |
| color | string | hex color code |
| timestamps | | |

### `transactions`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| amount | decimal(10,2) | positive, not null |
| date | date | indexed, not null |
| notes | text | nullable |
| category_id | bigint FK | |
| transaction_type | string | enum: income/expense |
| expense_kind | string | enum: fixed/variable, nullable (expenses only) |
| timestamps | | |

### `budgets`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| category_id | bigint FK | |
| month | integer | 1–12 |
| year | integer | positive |
| limit_amount | decimal(10,2) | positive |
| timestamps | | |

Unique index on `[category_id, month, year]`.

**Relationships:**
- `Category` → has_many `transactions` (dependent: destroy), has_many `budgets` (dependent: destroy)
- `Transaction` → belongs_to `category`
- `Budget` → belongs_to `category`

**Seeds:** Eight default categories via `find_or_create_by!` (idempotent): Rent 🏠, Groceries 🛒, Dining Out 🍽️, Transport 🚌, Hobbies 🎨, Entertainment 🎬, Utilities 💡, Income 💰.

## API Endpoints

All endpoints under `/api`.

### Categories
| Method | Path | Description |
|---|---|---|
| GET | `/api/categories` | All categories ordered by name |
| POST | `/api/categories` | Create category |
| PATCH | `/api/categories/:id` | Update category |
| DELETE | `/api/categories/:id` | Delete category; 422 if transactions exist, 204 on success |

### Transactions
| Method | Path | Description |
|---|---|---|
| GET | `/api/transactions` | All transactions; filters: `category_id`, `transaction_type`, `expense_kind`, `start_date`, `end_date` |
| POST | `/api/transactions` | Create transaction (201/422) |
| DELETE | `/api/transactions/:id` | Delete transaction (204/404) |

### Budgets
| Method | Path | Description |
|---|---|---|
| GET | `/api/budgets?month=M&year=Y` | Budgets for given month/year with computed `spent_amount` and `remaining_amount`; defaults to current month/year |
| POST | `/api/budgets` | Upsert budget (find_or_initialize_by category+month+year) |

### Dashboard
| Method | Path | Description |
|---|---|---|
| GET | `/api/dashboard` | Aggregated data: `category_breakdown`, `monthly_trend` (6 months, zero-filled), `budget_health`, `pet_mood` |

**Error response shape:** `{ errors: {...} }` for validation failures, `{ error: "message" }` for domain rule violations.

## Key Files & Directories

```
backend/
├── app/
│   ├── controllers/api/
│   │   ├── categories_controller.rb
│   │   ├── transactions_controller.rb
│   │   ├── budgets_controller.rb
│   │   └── dashboard_controller.rb
│   └── models/
│       ├── category.rb
│       ├── transaction.rb
│       └── budget.rb
├── db/
│   ├── schema.rb
│   ├── migrate/
│   └── seeds.rb
└── spec/
    ├── requests/api/      # Request specs for all endpoints
    └── integration/       # User flow integration specs

frontend/
├── src/
│   ├── api/index.ts       # Typed API client, base URL from VITE_API_URL
│   ├── stores/            # Pinia stores (one per domain)
│   │   ├── categories.ts
│   │   ├── transactions.ts
│   │   ├── budgets.ts
│   │   └── dashboard.ts
│   ├── views/
│   │   ├── DashboardView.vue
│   │   ├── TransactionsView.vue
│   │   ├── CategoriesView.vue
│   │   └── BudgetsView.vue
│   ├── components/
│   │   ├── CategoryForm.vue      # Name + hex color picker + icon selector
│   │   ├── TransactionForm.vue
│   │   ├── SpendingPieChart.vue  # vue-chartjs Pie
│   │   ├── MonthlyTrendChart.vue # vue-chartjs Line (filled area)
│   │   └── PetMascot.vue         # CSS-animated character, 3 mood states
│   ├── router/index.ts
│   └── App.vue            # 220px fixed sidebar + RouterView
└── src/__tests__/         # Vitest component tests
```

## Patterns & Conventions

### Backend
- Controllers namespaced under `Api` module: `class Api::CategoriesController`
- `before_action :set_*` for member routes
- Strong params via private method per controller
- No serializers/jbuilder — uses inline `as_json` with `include:` options
- Enums stored as strings: `enum :transaction_type, { income: "income", expense: "expense" }`
- Raw SQL date extraction uses `Arel.sql` for safety; PostgreSQL `EXTRACT` for monthly grouping
- Monthly trend always returns exactly 6 data points (zero-filled)

### Frontend
- Pinia store per domain in `src/stores/`; store files export a single composable (e.g., `useCategoriesStore`)
- API layer centralized in `src/api/index.ts` — views/stores never call `fetch` directly
- TypeScript interfaces for all API data shapes: `Category`, `Transaction`, `Budget`, `DashboardData`
- Views lazy-loaded via Vue Router
- CSS custom properties for theming (`--color-background`, `--color-text`, etc.)
- Scoped styles in all components
- Color threshold pattern (green <70%, yellow 70–90%, red >90%) reused in budget progress bars

### Testing
- **Backend:** RSpec, factory_bot_rails, shoulda-matchers; request specs + integration specs
- **Frontend:** Vitest + @vue/test-utils + jsdom; Chart.js and vanilla-colorful globally stubbed/mocked
- Pinia stores mocked in component tests via `createTestingPinia`

## Dependencies

### Backend (Gemfile)
| Gem | Purpose |
|---|---|
| rails 8.1.2 | Framework |
| pg | PostgreSQL adapter |
| puma | Web server |
| rack-cors | Cross-origin requests for Vue frontend |
| solid_cache/queue/cable | Rails 8 defaults |
| rspec-rails | Test framework |
| factory_bot_rails | Test factories |
| shoulda-matchers | Model validation matchers |

### Frontend (package.json)
| Package | Purpose |
|---|---|
| vue 3.5.x | UI framework |
| vue-router 5.x | Client-side routing |
| pinia 3.x | State management |
| chart.js 4.x | Charting library |
| vue-chartjs 5.x | Vue wrapper for Chart.js |
| vanilla-colorful 0.7.x | Hex color picker web component |
| @vueuse/core 14.x | Composition utilities |
| typescript ~5.9 | Type safety |
| vite | Dev server + build tool |
| vitest | Unit test runner |
| @vue/test-utils | Component testing |

## Setup

```bash
# Start everything with Docker Compose
docker-compose up

# Or run manually:

# Backend
cd backend
bundle install
bundle exec rails db:create db:migrate db:seed
bundle exec rails server -b 0.0.0.0  # http://localhost:3000

# Frontend
cd frontend
npm install
npm run dev  # http://localhost:5173 (proxies /api → localhost:3000)
```

**Environment variables:**
- `VITE_API_URL` — backend base URL (frontend; defaults to `http://localhost:3000`)
- `DATABASE_URL` — PostgreSQL connection string (backend)
- `FRONTEND_URL` — for CORS whitelist (backend)

**Run tests:**
```bash
# Backend
cd backend && bundle exec rspec

# Frontend
cd frontend && npm run test:unit