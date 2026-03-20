# Collectibles Tracker — Project Context

## Overview
Collectibles Vault is a full-stack Rails + Vue.js application for tracking and organizing collectible items across multiple collections. It supports photo management, condition tracking, estimated value recording, and search/filter capabilities. Built with Rails 8 API backend and Vue 3 frontend.

## Architecture
- **Backend:** Ruby on Rails 8 (API mode), PostgreSQL, Active Storage for photos
- **Frontend:** Vue 3 + Vite, Pinia (state), Vue Router
- **Infrastructure:** Docker Compose (PostgreSQL 16, Rails on port 3000, Vite dev on port 5173)
- **Testing:** RSpec (backend), Vitest + @vue/test-utils (frontend)
- API proxy: Vite dev server proxies `/api` → `http://localhost:3000`

## Database schema

**collections**
- `id`, `name` (NOT NULL), `category`, `description`, `created_at`, `updated_at`

**items**
- `id`, `name` (NOT NULL), `condition` (integer enum: mint=0, near_mint=1, good=2, fair=3, poor=4, NOT NULL)
- `estimated_value` (decimal 10,2, nullable), `acquisition_date` (date), `notes`, `collection_id` (FK, NOT NULL)
- `created_at`, `updated_at`
- Index on `collection_id`

**active_storage_attachments / active_storage_blobs / active_storage_variant_records** — standard Active Storage tables; items use `has_many_attached :photos` with attachment name `"photos"`

## API endpoints

```
GET    /api/dashboard
GET    /api/collections
POST   /api/collections
GET    /api/collections/:id
PUT    /api/collections/:id
DELETE /api/collections/:id
GET    /api/collections/:collection_id/items
POST   /api/collections/:collection_id/items
GET    /api/items/search        (?query, collection_id, category, condition, value_min, value_max)
GET    /api/items/:id
PATCH  /api/items/:id
DELETE /api/items/:id
```

**Key response shapes:**
- Collections index/show include computed `item_count` and `total_value` (SQL aggregates via `left_joins.group.select`)
- Collections show includes `value_by_condition: { mint, near_mint, good, fair, poor }` (condition → USD sum)
- Items include `photos: [{ id, url, filename, content_type }]`; URLs generated with `host: request.base_url`
- Dashboard includes `total_collections`, `total_items`, `total_estimated_value`, `value_by_condition`, `recently_added_items` (10 most recent, each with `collection_name`)
- Validation errors: `422` with `{ "errors": ["..."] }`

**Photo upload/removal:**
- Upload: `multipart/form-data`, param `photos[]`
- Remove: PATCH with `remove_photo_ids[]` (blob IDs) to purge specific photos

## Key files & directories

```
collectibles-tracker/
├── backend/
│   ├── app/
│   │   ├── controllers/api/
│   │   │   ├── collections_controller.rb   # CRUD + SQL aggregates + value_by_condition helper
│   │   │   ├── items_controller.rb         # CRUD + search + photo attach/purge + serialize_item helper
│   │   │   └── dashboard_controller.rb     # Aggregate stats + recently_added_items
│   │   └── models/
│   │       ├── collection.rb               # has_many :items, dependent: :destroy
│   │       └── item.rb                     # belongs_to :collection, has_many_attached :photos, enum, scope :search
│   ├── config/routes.rb
│   ├── db/schema.rb
│   └── spec/
│       ├── factories/                       # FactoryBot (collections.rb, items.rb)
│       ├── models/                          # collection_spec.rb, item_spec.rb
│       └── requests/api/                   # collections_spec.rb, items_spec.rb, dashboard_spec.rb, integration_spec.rb
├── frontend/src/
│   ├── App.vue                              # Root layout with sidebar nav
│   ├── router/index.ts                      # 5 routes (/, /collections, /collections/:id, /collections/:id/items/:itemId, /search)
│   ├── services/api.ts                      # fetch wrapper + all API functions
│   ├── stores/
│   │   ├── collections.ts                  # fetchCollections, fetchCollection, createCollection, updateCollection, deleteCollection
│   │   ├── items.ts                        # fetchItems, fetchItem, createItem, updateItem, deleteItem, searchItems
│   │   └── dashboard.ts                    # fetchDashboard
│   ├── views/
│   │   ├── DashboardView.vue               # Stat cards + ValueBreakdown + recently added
│   │   ├── CollectionsView.vue             # Collections grid + CollectionModal
│   │   ├── CollectionDetailView.vue        # Items grid/list toggle + ItemModal + ValueBreakdown
│   │   ├── ItemDetailView.vue              # Full item detail + photo gallery + edit
│   │   └── SearchView.vue                  # SearchFilterPanel + results grid
│   └── components/
│       ├── CollectionModal.vue             # Create/edit collection (dual-mode)
│       ├── ItemModal.vue                   # Create/edit item with photo upload/removal (dual-mode)
│       ├── SearchFilterPanel.vue           # Debounced filter UI, emits `search` event
│       └── ValueBreakdown.vue              # Condition → USD breakdown (reusable)
├── docker-compose.yml
└── .env.example
```

## Patterns & conventions

- **API serialization:** Inline helper methods on controllers (`serialize_item`, `build_value_by_condition`); no dedicated serializer classes
- **SQL aggregates:** Computed at DB level via `left_joins(:items).group(:id).select(...)` to avoid N+1
- **Photo URLs:** Always include `host: request.base_url` for CORS; blob ID used for removal
- **FormData submission:** ItemModal uses raw `fetch()` (not `apiFetch`) to preserve multipart boundary
- **Store actions:** Return `string[] | null` for mutation actions (null = success, array = validation errors)
- **Condition enum:** Integer-backed in DB (`mint: 0, near_mint: 1, ...`); string values in API responses
- **Search:** `Item.search` scope chains ILIKE on name/notes for query, plus equality filters; no full-text search
- **View toggle:** Grid/list persisted in `sessionStorage` key `itemViewMode`
- **Debouncing:** 300ms via Vue watcher (no lodash); applied in SearchFilterPanel
- **Currency:** `Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })`
- **ValueBreakdown order:** Always Mint → Near Mint → Good → Fair → Poor; zero-value rows hidden
- **Testing:** FactoryBot with sequences for unique names; frontend tests use `vi.mock()` + pinia test utils

## Dependencies

**Backend (key gems):**
- `rails ~> 8.1.2` — API framework
- `pg ~> 1.1` — PostgreSQL adapter
- `rack-cors` — CORS for Vue frontend
- `image_processing ~> 1.2` — Active Storage image variants
- `rspec-rails ~> 7.0`, `factory_bot_rails`, `shoulda-matchers ~> 6.0` — testing

**Frontend (key packages):**
- `vue ^3.5.29` — UI framework
- `pinia ^3.0.4` — state management
- `vue-router ^5.0.3` — client-side routing
- `vite ^7.3.1` — build tool / dev server
- `vitest ^4.0.18`, `@vue/test-utils ^2.4.6` — testing

## Setup

**Docker (recommended):**
```bash
cp .env.example .env
# Set RAILS_MASTER_KEY from backend/config/master.key
docker-compose up
# App: http://localhost:5173
```

**Local development:**
```bash
# Backend
cd backend && bundle install
rails db:create db:migrate
rails server                   # http://localhost:3000

# Frontend (separate terminal)
cd frontend && npm install
npm run dev                    # http://localhost:5173
```

**Tests:**
```bash
# Backend
cd backend && bundle exec rspec

# Frontend
cd frontend && npm run test:unit